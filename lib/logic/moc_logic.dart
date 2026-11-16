import 'dart:convert';
import 'dart:isolate';

import 'package:brick_collector/model/CollectablePartGroup.dart';
import 'package:brick_collector/model/moc.dart';
import 'package:brick_collector/common_libs.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class MocLogic {
  // Sized for retina cards on macOS/iPad; phone cards downsample for free.
  static const int _maxThumbWidth = 1280;
  static const int _jpegQuality = 92;
  // Pre-rendered images smaller than this are stored verbatim to avoid any
  // recompression artifacts. 600 KB raw -> ~800 KB base64 in the Firestore
  // doc, still well under the 1 MiB document limit.
  static const int _passthroughMaxBytes = 600 * 1024;

  /// Left free when sizing an image, so the parts can still grow (collected
  /// counts, renames, a few added parts) without hitting Firestore's limit.
  static const int _growthReserve = 50 * 1000;

  /// Below this much room left in the MOC document, don't attempt an image.
  static const int _minImageBudget = 20 * 1000;

  /// Images aren't shrunk below this width to fit the document.
  static const int _minImageWidth = 160;

  Stream<List<Moc>> get outMocs => dbLogic.watchMocs();

  /// Creates a MOC and saves it in the background; its firestoreId is set on
  /// return.
  Moc addNewMoc(String name, {String? sourceUrl, String? imageUrl}) {
    final newMoc = Moc(name: name)
      ..sourceUrl = sourceUrl
      ..imageUrl = imageUrl;
    saveMoc(newMoc);
    return newMoc;
  }

  /// Saves in the background; see [DbLogic.saveMoc].
  void saveMoc(Moc moc) => dbLogic.saveMoc(moc);

  /// Deletes in the background; see [DbLogic.deleteMoc].
  void deleteMoc(Moc moc) => dbLogic.deleteMoc(moc);

  void deletePart(Moc moc, CollectablePartGroup group, BrickPart part) {
    group.parts.remove(part);
    moc.parts?.remove(part);
    saveMoc(moc);
  }

  /// Opens the gallery picker. Returns the raw file bytes, or null if the
  /// user cancelled. Split from [setMocImageFromBytes] so the UI can show a
  /// progress indicator only during the encode/save step, not while the user
  /// is browsing their gallery.
  Future<List<int>?> pickImageBytes() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return null;
    return picked.readAsBytes();
  }

  /// Stores the given image bytes inline on the MOC document as base64.
  /// Small pre-rendered JPEGs are passed through verbatim; larger inputs are
  /// downscaled with a high-quality filter and re-encoded as JPEG. Either is
  /// shrunk further to fit the room the parts leave in the MOC's Firestore
  /// document, minus a reserve so the parts can still grow afterwards. The
  /// image work runs on a background isolate. Throws [MocTooLargeException]
  /// (leaving the MOC unchanged) if it can't be made to fit.
  Future<void> setMocImageFromBytes(Moc moc, List<int> bytes) async {
    final raw = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    final partsBytes = moc.documentBytesWithoutImage;
    final budget = Moc.maxDocumentBytes - partsBytes - _growthReserve;
    if (budget < _minImageBudget) {
      throw MocTooLargeException("This MOC's parts already take ${kilobytes(partsBytes)} of the ~1 MB a MOC "
          'may use, which leaves no room for an image.');
    }
    final fitted = await Isolate.run(() => _fitImage(raw, budget));
    moc.imageBase64 = base64Encode(fitted);
    saveMoc(moc);
  }

  /// [raw] as a JPEG whose base64 is at most [budget] bytes. Runs on a
  /// background isolate, so it only uses its arguments and constants.
  static Uint8List _fitImage(Uint8List raw, int budget) {
    final decoded = img.decodeImage(raw);
    if (decoded == null) {
      throw const FormatException('Could not decode selected image');
    }
    var width = min(decoded.width, _maxThumbWidth);
    var fitted = decoded.width <= _maxThumbWidth && raw.length <= _passthroughMaxBytes && _isJpeg(raw)
        ? raw
        : _encodeJpg(decoded, width);
    while (_base64Length(fitted.length) > budget) {
      // JPEG size scales roughly with pixel count, i.e. with width squared.
      final scale = sqrt(budget / _base64Length(fitted.length)) * 0.9;
      width = min((width * scale).floor(), width - 1);
      if (width < _minImageWidth) {
        throw MocTooLargeException('Could not shrink the image to fit the ${kilobytes(budget)} left in this MOC.');
      }
      fitted = _encodeJpg(decoded, width);
    }
    return fitted;
  }

  static Uint8List _encodeJpg(img.Image decoded, int width) {
    final resized = decoded.width > width
        ? img.copyResize(
            decoded,
            width: width,
            // 'average' is a box filter — the best choice for downscaling
            // sharp content like LEGO renders. 'nearest' (the default) is
            // what was making things look blocky.
            interpolation: img.Interpolation.average,
          )
        : decoded;
    return Uint8List.fromList(img.encodeJpg(resized, quality: _jpegQuality));
  }

  static int _base64Length(int bytes) => 4 * ((bytes + 2) ~/ 3);

  static bool _isJpeg(Uint8List b) =>
      b.length >= 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF;

  void clearMocImage(Moc moc) {
    moc.imageBase64 = null;
    saveMoc(moc);
  }
}
