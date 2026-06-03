import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class Detection {
  Detection(this.box, this.confidence, this.classId);
  final Rect box;
  final double confidence;
  final int classId;
}

class DetectionResult {
  DetectionResult(this.detections, this.imageWidth, this.imageHeight);
  final List<Detection> detections;
  final int imageWidth;
  final int imageHeight;
}

/// Runs a YOLOv8 TFLite model from assets and returns bounding boxes.
///
/// Expects model output shape `[1, 4 + numClasses, numAnchors]` (YOLOv8 default).
/// Output coords are assumed to be in input pixel space (0..inputSize).
class LegoDetector {
  LegoDetector({
    this.modelAsset = 'assets/models/lego.tflite',
    this.inputSize = 1280,
    this.confidenceThreshold = 0.15,
    this.iouThreshold = 0.45,
    this.maxBoxAreaFraction = 0.20,
  });

  final String modelAsset;
  final int inputSize;
  final double confidenceThreshold;
  final double iouThreshold;
  final double maxBoxAreaFraction;

  Interpreter? _interpreter;

  bool get isReady => _interpreter != null;

  Future<void> init() async {
    if (_interpreter != null) return;
    _interpreter = await Interpreter.fromAsset(modelAsset);
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }

  Future<DetectionResult> detect(File file) async {
    final interp = _interpreter;
    if (interp == null) {
      throw StateError('LegoDetector.init() was not called');
    }

    final bytes = await file.readAsBytes();
    final src = img.decodeImage(bytes);
    if (src == null) {
      throw StateError('Could not decode image');
    }

    final scale = math.min(inputSize / src.width, inputSize / src.height);
    final newW = (src.width * scale).round();
    final newH = (src.height * scale).round();
    final padX = ((inputSize - newW) / 2).floor();
    final padY = ((inputSize - newH) / 2).floor();

    final resized = img.copyResize(src, width: newW, height: newH);
    final padded = img.Image(width: inputSize, height: inputSize);
    img.fill(padded, color: img.ColorRgb8(114, 114, 114));
    img.compositeImage(padded, resized, dstX: padX, dstY: padY);

    final input = _imageToInput(padded);

    final outShape = interp.getOutputTensor(0).shape;
    final output = List.generate(
      outShape[0],
      (_) => List.generate(outShape[1], (_) => List<double>.filled(outShape[2], 0.0)),
    );

    interp.run(input, output);

    final detections = _parseYolov8Output(
      output[0],
      scale: scale,
      padX: padX,
      padY: padY,
      origW: src.width,
      origH: src.height,
    );

    final kept = _nms(detections, iouThreshold);
    return DetectionResult(kept, src.width, src.height);
  }

  List<List<List<List<double>>>> _imageToInput(img.Image image) {
    return List.generate(1, (_) {
      return List.generate(inputSize, (y) {
        return List.generate(inputSize, (x) {
          final p = image.getPixel(x, y);
          return [p.r / 255.0, p.g / 255.0, p.b / 255.0];
        });
      });
    });
  }

  List<Detection> _parseYolov8Output(
    List<List<double>> out, {
    required double scale,
    required int padX,
    required int padY,
    required int origW,
    required int origH,
  }) {
    // YOLOv8 standard layout is [channels, anchors] (channels = 4 + numClasses,
    // typically 5 for single-class). Some TFLite exports come transposed as
    // [anchors, channels] — detect by which dim is smaller.
    final List<List<double>> chFirst = out.length < out[0].length
        ? out
        : List.generate(out[0].length, (c) => List.generate(out.length, (i) => out[i][c]));

    final numChannels = chFirst.length;
    final numAnchors = chFirst[0].length;
    final numClasses = numChannels - 4;

    // Ultralytics TFLite export emits coords normalized to [0,1]; the .pt model
    // emits pixel coords. Detect by sampling the largest box value.
    double maxCoord = 0;
    final stride = math.max(1, numAnchors ~/ 100);
    for (int i = 0; i < numAnchors; i += stride) {
      for (int c = 0; c < 4; c++) {
        final v = chFirst[c][i];
        if (v > maxCoord) maxCoord = v;
      }
    }
    final coordScale = maxCoord <= 1.5 ? inputSize.toDouble() : 1.0;

    int kept = 0;
    final results = <Detection>[];
    for (int i = 0; i < numAnchors; i++) {
      double maxScore = 0;
      int maxClass = 0;
      for (int c = 0; c < numClasses; c++) {
        final s = chFirst[4 + c][i];
        if (s > maxScore) {
          maxScore = s;
          maxClass = c;
        }
      }
      if (maxScore < confidenceThreshold) continue;
      kept++;

      final cx = chFirst[0][i] * coordScale;
      final cy = chFirst[1][i] * coordScale;
      final w = chFirst[2][i] * coordScale;
      final h = chFirst[3][i] * coordScale;

      final x1 = ((cx - w / 2) - padX) / scale;
      final y1 = ((cy - h / 2) - padY) / scale;
      final x2 = ((cx + w / 2) - padX) / scale;
      final y2 = ((cy + h / 2) - padY) / scale;

      final box = Rect.fromLTRB(
        x1.clamp(0, origW.toDouble()),
        y1.clamp(0, origH.toDouble()),
        x2.clamp(0, origW.toDouble()),
        y2.clamp(0, origH.toDouble()),
      );
      if (box.width <= 1 || box.height <= 1) continue;
      final imgArea = origW * origH;
      if (imgArea > 0 && (box.width * box.height) / imgArea > maxBoxAreaFraction) {
        continue;
      }

      results.add(Detection(box, maxScore, maxClass));
    }

    debugPrint(
      'LegoDetector: out=${out.length}x${out[0].length} '
      'chs=$numChannels anchors=$numAnchors '
      'coordScale=$coordScale maxCoord=${maxCoord.toStringAsFixed(3)} '
      'aboveConf=$kept boxes=${results.length}',
    );
    return results;
  }

  List<Detection> _nms(List<Detection> dets, double iouTh) {
    dets.sort((a, b) => b.confidence.compareTo(a.confidence));
    final keep = <Detection>[];
    for (final d in dets) {
      bool overlaps = false;
      for (final k in keep) {
        if (_iou(d.box, k.box) > iouTh) {
          overlaps = true;
          break;
        }
      }
      if (!overlaps) keep.add(d);
    }
    return keep;
  }

  double _iou(Rect a, Rect b) {
    final inter = a.intersect(b);
    if (inter.width <= 0 || inter.height <= 0) return 0;
    final interArea = inter.width * inter.height;
    final unionArea = a.width * a.height + b.width * b.height - interArea;
    return interArea / unionArea;
  }
}
