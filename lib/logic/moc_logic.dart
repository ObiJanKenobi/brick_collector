import 'dart:convert';

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

  Stream<List<Moc>> get outMocs => dbLogic.watchMocs();

  Future<Moc> addNewMoc(String name, {String? sourceUrl, String? imageUrl}) async {
    final newMoc = Moc(name: name);
    newMoc.sourceUrl = sourceUrl;
    newMoc.imageUrl = imageUrl;
    await saveMoc(newMoc);
    return newMoc;
  }

  Future<Moc> saveMoc(Moc moc) async {
    await dbLogic.saveMoc(moc);
    return moc;
  }

  Future<void> deleteMoc(Moc moc) async {
    await dbLogic.deleteMoc(moc);
  }

  Future<void> deletePart(Moc moc, CollectablePartGroup group, BrickPart part) async {
    group.parts.remove(part);
    moc.parts?.remove(part);
    await saveMoc(moc);
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
  /// downscaled with a high-quality filter and re-encoded as JPEG.
  Future<void> setMocImageFromBytes(Moc moc, List<int> bytes) async {
    final raw = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    final decoded = img.decodeImage(raw);
    if (decoded == null) {
      throw const FormatException('Could not decode selected image');
    }

    final Uint8List finalBytes;
    if (decoded.width <= _maxThumbWidth &&
        raw.length <= _passthroughMaxBytes &&
        _isJpeg(raw)) {
      finalBytes = raw;
    } else {
      final resized = decoded.width > _maxThumbWidth
          ? img.copyResize(
              decoded,
              width: _maxThumbWidth,
              // 'average' is a box filter — the best choice for downscaling
              // sharp content like LEGO renders. 'nearest' (the default) is
              // what was making things look blocky.
              interpolation: img.Interpolation.average,
            )
          : decoded;
      finalBytes = Uint8List.fromList(img.encodeJpg(resized, quality: _jpegQuality));
    }

    moc.imageBase64 = base64Encode(finalBytes);
    await saveMoc(moc);
  }

  static bool _isJpeg(Uint8List b) =>
      b.length >= 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF;

  Future<void> clearMocImage(Moc moc) async {
    moc.imageBase64 = null;
    await saveMoc(moc);
  }
}
