import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

class CoordinateUtil {
  static double translateX({
    required double x,
    required Size canvasSize,
    required Size imageSize,
    required InputImageRotation rotation,
    required CameraLensDirection cameraLensDirection,
  }) {
    double imageWidth = Platform.isIOS ? imageSize.width : imageSize.height;
    switch (rotation) {
      case InputImageRotation.rotation90deg:
        return x * canvasSize.width / imageWidth;
      case InputImageRotation.rotation270deg:
        return canvasSize.width - x * canvasSize.width / imageWidth;
      case InputImageRotation.rotation0deg:
      case InputImageRotation.rotation180deg:
        double translatedX = x * canvasSize.width / imageSize.width;
        return cameraLensDirection == CameraLensDirection.front
            ? canvasSize.width - translatedX
            : translatedX;
    }
  }

  static double translateY({
    required double y,
    required Size canvasSize,
    required Size imageSize,
    required InputImageRotation rotation,
    required CameraLensDirection cameraLensDirection,
  }) {
    double imageHeight = Platform.isIOS ? imageSize.height : imageSize.width;
    switch (rotation) {
      case InputImageRotation.rotation90deg:
      case InputImageRotation.rotation270deg:
        return y * canvasSize.height / imageHeight;
      case InputImageRotation.rotation0deg:
      case InputImageRotation.rotation180deg:
        return y * canvasSize.height / imageSize.height;
    }
  }

  static bool hasPointInRange(RRect focusedRRect, Rect textRect) {
    final double minX = focusedRRect.left;
    final double maxX = focusedRRect.right;
    if (textRect.left < minX || textRect.right > maxX) {
      return false;
    }
    final double minY = focusedRRect.top;
    final double maxY = focusedRRect.bottom;
    if (textRect.top < minY || textRect.bottom > maxY) {
      return false;
    }
    return true;
  }
}
