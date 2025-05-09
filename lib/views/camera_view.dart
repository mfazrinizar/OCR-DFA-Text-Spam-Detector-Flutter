import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraView extends StatefulWidget {
  final void Function(String imagePath) onImageCaptured;

  const CameraView({super.key, required this.onImageCaptured});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  CameraController? _controller;
  bool _isBusy = false;
  String? _error;
  final GlobalKey _cameraKey = GlobalKey();
  double? _cameraPreviewScale;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      _controller = CameraController(camera, ResolutionPreset.high);
      await _controller!.initialize();
      setState(() {});
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    setState(() => _isBusy = true);
    final file = await _controller!.takePicture();
    widget.onImageCaptured(file.path);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: Center(child: Text('Camera error: $_error')),
      );
    }
    if (_controller == null || !_controller!.value.isInitialized) {
      return Scaffold(
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Calculate scale after first frame
    if (_cameraPreviewScale == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final screenSize = MediaQuery.of(context).size;
        final previewBox =
            _cameraKey.currentContext?.findRenderObject() as RenderBox?;
        if (previewBox != null) {
          final previewSize = previewBox.size;
          final scale = screenSize.width / previewSize.width;
          if (mounted) {
            setState(() {
              _cameraPreviewScale = scale;
            });
          }
        }
      });
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Container(
              key: _cameraKey,
              child: Transform.scale(
                alignment: Alignment.center,
                scale: _cameraPreviewScale ?? 1,
                child: CameraPreview(_controller!),
              ),
            ),
          ),
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: IconButton.filled(
                iconSize: 48,
                icon: const Icon(Icons.camera),
                onPressed: _isBusy ? null : _capture,
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
