import 'dart:io';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:ocr_dfa_text_spam_detector/widgets/ocr_painter.dart';
import '../utils/camera_util.dart';

class OCRView extends StatefulWidget {
  const OCRView({
    super.key,
    this.focusedAreaWidth = 200.0,
    this.focusedAreaHeight = 40.0,
    this.focusedAreaCenter = Offset.zero,
    this.focusedAreaRadius = const Radius.circular(8.0),
    this.focusedAreaPaint,
    this.unfocusedAreaPaint,
    this.textBackgroundPaint,
    this.paintTextStyle,
    required this.onScanText,
    this.script = TextRecognitionScript.latin,
    this.showDropdown = true,
    this.onCameraFeedReady,
    this.onDetectorViewModeChanged,
    this.onCameraLensDirectionChanged,
  });

  final double? focusedAreaWidth;
  final double? focusedAreaHeight;
  final Offset? focusedAreaCenter;
  final Radius? focusedAreaRadius;
  final Paint? focusedAreaPaint;
  final Paint? unfocusedAreaPaint;
  final Paint? textBackgroundPaint;
  final ui.TextStyle? paintTextStyle;
  final Function? onScanText;
  final TextRecognitionScript script;
  final bool showDropdown;
  final VoidCallback? onCameraFeedReady;
  final VoidCallback? onDetectorViewModeChanged;
  final Function(CameraLensDirection direction)? onCameraLensDirectionChanged;

  @override
  State<OCRView> createState() => _OCRViewState();
}

class _OCRViewState extends State<OCRView> {
  late TextRecognizer _textRecognizer;
  TextRecognitionScript _script = TextRecognitionScript.latin;
  bool _canProcess = true;
  bool _isLoading = false;
  CustomPaint? _customPaint;
  final CameraLensDirection _cameraLensDirection = CameraLensDirection.back;
  static List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _cameraIndex = -1;

  Future<void> _processImage(InputImage inputImage) async {
    if (!_canProcess || _isLoading) {
      return;
    }
    _isLoading = true;
    final recognizedText = await _textRecognizer.processImage(inputImage);
    final bool isEmptyImageMetadata = inputImage.metadata?.size == null ||
        inputImage.metadata?.rotation == null;
    if (isEmptyImageMetadata) {
      _customPaint = null;
    } else {
      final painter = OCRPainter(
        recognizedText: recognizedText,
        imageSize: inputImage.metadata!.size,
        rotation: inputImage.metadata!.rotation,
        cameraLensDirection: _cameraLensDirection,
        focusedAreaWidth: widget.focusedAreaWidth!,
        focusedAreaHeight: widget.focusedAreaHeight!,
        focusedAreaCenter: widget.focusedAreaCenter!,
        focusedAreaRadius: widget.focusedAreaRadius!,
        focusedAreaPaint: widget.focusedAreaPaint,
        unfocusedAreaPaint: widget.unfocusedAreaPaint,
        textBackgroundPaint: widget.textBackgroundPaint,
        uiTextStyle: widget.paintTextStyle,
        onScanText: widget.onScanText,
      );
      _customPaint = CustomPaint(painter: painter);
    }
    _isLoading = false;
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _startLiveFeed() async {
    final camera = _cameras[_cameraIndex];
    final imageFormatGroup =
        Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888;
    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: imageFormatGroup,
    );
    _controller?.initialize().then((_) {
      if (!mounted) {
        return;
      }
      _controller?.startImageStream(_processCameraImage).then((value) {
        if (widget.onCameraFeedReady != null) {
          widget.onCameraFeedReady!();
        }
        if (widget.onCameraLensDirectionChanged != null) {
          widget.onCameraLensDirectionChanged!(camera.lensDirection);
        }
      });
      setState(() {});
    });
  }

  Future<void> _stopLiveFeed() async {
    await _controller?.stopImageStream();
    await _controller?.dispose();
    _controller = null;
  }

  void _processCameraImage(CameraImage image) {
    final inputImage = CameraUtil.inputImageFromCameraImage(
      image: image,
      controller: _controller,
      cameras: _cameras,
      cameraIndex: _cameraIndex,
    );
    // print('InputImage: $inputImage');
    // print('Inside _processCameraImage');

    if (inputImage == null) {
      // print('InputImage is null');

      return;
    }

    _processImage(inputImage);
  }

  Future<void> _initialize() async {
    if (_cameras.isEmpty) {
      _cameras = await availableCameras();
    }
    for (var i = 0; i < _cameras.length; i++) {
      if (_cameras[i].lensDirection == _cameraLensDirection) {
        _cameraIndex = i;
        break;
      }
    }
    if (_cameraIndex != -1) {
      _startLiveFeed();
    }
  }

  @override
  void initState() {
    _script = widget.script;
    _textRecognizer = TextRecognizer(script: _script);
    _initialize();
    super.initState();
  }

  @override
  void dispose() {
    _canProcess = false;
    _textRecognizer.close();
    _stopLiveFeed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isNotInitialized = _cameras.isEmpty ||
        _controller == null ||
        _controller?.value.isInitialized == false;
    if (isNotInitialized) {
      return const SizedBox.shrink();
    }
    return CameraPreview(
      _controller!,
      child: _customPaint,
    );
  }
}
