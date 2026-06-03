import 'dart:io';
import 'dart:ui' as ui;

import 'package:brick_collector/common_libs.dart';
import 'package:brick_collector/services/lego_detector.dart';
import 'package:brick_collector/ui/nav_menu.dart';
import 'package:image_picker/image_picker.dart';

class PieceCounterScreen extends StatefulWidget {
  const PieceCounterScreen({super.key});

  @override
  State<PieceCounterScreen> createState() => _PieceCounterScreenState();
}

class _PieceCounterScreenState extends State<PieceCounterScreen> {
  final ImagePicker _picker = ImagePicker();
  final LegoDetector _detector = LegoDetector();

  ui.Image? _image;
  List<Detection> _detections = const [];
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _detector.dispose();
    _image?.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final XFile? picked = await _picker.pickImage(source: source, imageQuality: 95);
      if (picked == null) {
        setState(() => _busy = false);
        return;
      }

      if (!_detector.isReady) {
        await _detector.init();
      }

      final file = File(picked.path);
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();

      final result = await _detector.detect(file);

      _image?.dispose();
      setState(() {
        _image = frame.image;
        _detections = result.detections;
        _busy = false;
      });
    } catch (e) {
      setState(() {
        _busy = false;
        _error = _humanizeError(e);
      });
    }
  }

  String _humanizeError(Object e) {
    final msg = e.toString();
    if (msg.contains('Unable to load asset') || msg.contains('models/lego.tflite')) {
      return 'Model not found.\nDrop a YOLOv8 .tflite file at\nassets/models/lego.tflite';
    }
    return msg;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Count Pieces')),
      drawer: const Drawer(child: NavMenu()),
      body: Column(
        children: [
          Expanded(child: _buildPreview()),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (_busy) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      );
    }
    if (_image == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Pick or shoot a photo of LEGO pieces.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final img = _image!;
    return Center(
      child: AspectRatio(
        aspectRatio: img.width / img.height,
        child: CustomPaint(
          painter: _DetectionPainter(image: img, detections: _detections),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final count = _detections.length;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white12)),
        ),
        child: Row(
          children: [
            if (_image != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count piece${count == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.highlightColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            const Spacer(),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _pick(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Gallery'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _busy ? null : () => _pick(ImageSource.camera),
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Camera'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetectionPainter extends CustomPainter {
  _DetectionPainter({required this.image, required this.detections});

  final ui.Image image;
  final List<Detection> detections;

  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, src, dst, Paint());

    final scaleX = size.width / image.width;
    final scaleY = size.height / image.height;

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = AppColors.highlightColor;

    for (final d in detections) {
      final r = Rect.fromLTRB(
        d.box.left * scaleX,
        d.box.top * scaleY,
        d.box.right * scaleX,
        d.box.bottom * scaleY,
      );
      canvas.drawRect(r, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _DetectionPainter old) =>
      old.image != image || old.detections != detections;
}
