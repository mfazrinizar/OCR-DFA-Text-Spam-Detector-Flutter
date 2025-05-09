import 'dart:ui' as ui;
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../utils/coordinate_util.dart';

class OCRPainter extends CustomPainter {
  OCRPainter({
    required this.recognizedText,
    required this.imageSize,
    required this.rotation,
    required this.cameraLensDirection,
    required this.focusedAreaWidth,
    required this.focusedAreaHeight,
    required this.focusedAreaCenter,
    required this.focusedAreaRadius,
    this.focusedAreaPaint,
    this.unfocusedAreaPaint,
    this.textBackgroundPaint,
    this.uiTextStyle,
    this.onScanText,
  });

  final RecognizedText recognizedText;
  final Size imageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;
  final double focusedAreaWidth;
  final double focusedAreaHeight;
  final Offset focusedAreaCenter;
  final Radius focusedAreaRadius;
  final Paint? focusedAreaPaint;
  final Paint? unfocusedAreaPaint;
  final Paint? textBackgroundPaint;
  final ui.TextStyle? uiTextStyle;
  final Function? onScanText;

  void _drawFocusedArea(Canvas canvas, RRect focusedRRect) {
    final Paint defaultPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.blue;
    canvas.drawRRect(
      focusedRRect,
      focusedAreaPaint ?? defaultPaint,
    );
  }

  void _drawUnfocusedArea(Canvas canvas, Size size, RRect focusedRRect) {
    final Offset deviceCenter = Offset(size.width / 2, size.height / 2);
    final Rect deviceRect = Rect.fromCenter(
      center: deviceCenter,
      width: size.width,
      height: size.height,
    );
    final Paint defaultPaint = Paint()..color = const Color(0x99000000);
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(deviceRect),
        Path()..addRRect(focusedRRect),
      ),
      unfocusedAreaPaint ?? defaultPaint,
    );
  }

  void _drawText(Canvas canvas, TextBlock textBlock, Rect textRect) {
    final ui.TextStyle defaultStyle = ui.TextStyle(
      color: Colors.lightGreenAccent,
      background: Paint()..color = const Color(0x99000000),
    );
    final ParagraphBuilder builder = ParagraphBuilder(
      ParagraphStyle(),
    );
    builder.pushStyle(uiTextStyle ?? defaultStyle);
    builder.addText(textBlock.text);
    builder.pop();
    canvas.drawParagraph(
      builder.build()
        ..layout(
          ParagraphConstraints(width: (textRect.right - textRect.left).abs()),
        ),
      Offset(textRect.left, textRect.top),
    );
  }

  void _drawTextBackground(Canvas canvas, TextBlock textBlock, Size size) {
    final List<Offset> cornerPoints = <Offset>[];
    for (final point in textBlock.cornerPoints) {
      final double x = CoordinateUtil.translateX(
        x: point.x.toDouble(),
        canvasSize: size,
        imageSize: imageSize,
        rotation: rotation,
        cameraLensDirection: cameraLensDirection,
      );
      final double y = CoordinateUtil.translateY(
        y: point.y.toDouble(),
        canvasSize: size,
        imageSize: imageSize,
        rotation: rotation,
        cameraLensDirection: cameraLensDirection,
      );
      cornerPoints.add(Offset(x, y));
    }
    cornerPoints.add(cornerPoints.first);
    final Paint defaultPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.lightGreenAccent;
    canvas.drawPoints(
      PointMode.polygon,
      cornerPoints,
      textBackgroundPaint ?? defaultPaint,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final RRect focusedRRect = RRect.fromLTRBR(
      ((size.width - focusedAreaWidth) / 2) + focusedAreaCenter.dx,
      ((size.height - focusedAreaHeight) / 2) + focusedAreaCenter.dy,
      ((size.width - focusedAreaWidth) / 2 + focusedAreaWidth) +
          focusedAreaCenter.dx,
      ((size.height - focusedAreaHeight) / 2 + focusedAreaHeight) +
          focusedAreaCenter.dy,
      focusedAreaRadius,
    );

    _drawUnfocusedArea(canvas, size, focusedRRect);
    _drawFocusedArea(canvas, focusedRRect);

    for (final textBlock in recognizedText.blocks) {
      final double textLeft = CoordinateUtil.translateX(
        x: textBlock.boundingBox.left,
        canvasSize: size,
        imageSize: imageSize,
        rotation: rotation,
        cameraLensDirection: cameraLensDirection,
      );
      final double textTop = CoordinateUtil.translateY(
        y: textBlock.boundingBox.top,
        canvasSize: size,
        imageSize: imageSize,
        rotation: rotation,
        cameraLensDirection: cameraLensDirection,
      );
      final double textRight = CoordinateUtil.translateX(
        x: textBlock.boundingBox.right,
        canvasSize: size,
        imageSize: imageSize,
        rotation: rotation,
        cameraLensDirection: cameraLensDirection,
      );
      final double textBottom = CoordinateUtil.translateY(
        y: textBlock.boundingBox.bottom,
        canvasSize: size,
        imageSize: imageSize,
        rotation: rotation,
        cameraLensDirection: cameraLensDirection,
      );
      final Rect textRect =
          Rect.fromLTRB(textLeft, textTop, textRight, textBottom);

      final bool hasPointInRange =
          CoordinateUtil.hasPointInRange(focusedRRect, textRect);
      if (hasPointInRange) {
        _drawTextBackground(canvas, textBlock, size);
        _drawText(canvas, textBlock, textRect);
        if (onScanText != null) {
          onScanText!(textBlock.text);
        }
      }
    }
  }

  @override
  bool shouldRepaint(OCRPainter oldDelegate) {
    return oldDelegate.recognizedText != recognizedText;
  }
}
