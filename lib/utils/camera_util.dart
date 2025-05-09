import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

class CameraUtil {
  static final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  static InputImage? inputImageFromCameraImage({
    required CameraImage image,
    required CameraController? controller,
    required List<CameraDescription> cameras,
    required int cameraIndex,
  }) {
    if (controller == null) return null;
    final camera = cameras[cameraIndex];
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      int? rotationCompensation =
          _orientations[controller.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;

    // print('Camera image format group: ${image.format.group}');
    // print('Camera image format raw: ${image.format.raw}');

    // Android: YUV420 (3 planes)
    if (Platform.isAndroid && image.format.group == ImageFormatGroup.yuv420) {
      final int width = image.width;
      final int height = image.height;
      final int ySize = width * height;
      final int uvSize = width * height ~/ 2;

      final Uint8List nv21Bytes = Uint8List(ySize + uvSize);

      // Copy Y plane
      int offset = 0;
      for (int i = 0; i < height; i++) {
        nv21Bytes.setRange(offset, offset + width, image.planes[0].bytes,
            i * image.planes[0].bytesPerRow);
        offset += width;
      }

      // Interleave VU (planes 2 and 1)
      final int uvRowStride = image.planes[1].bytesPerRow;
      final int uvPixelStride = image.planes[1].bytesPerPixel!;
      // int uvIndex = 0;
      for (int i = 0; i < height ~/ 2; i++) {
        for (int j = 0; j < width ~/ 2; j++) {
          final int vuIndex = i * uvRowStride + j * uvPixelStride;
          nv21Bytes[offset++] = image.planes[2].bytes[vuIndex]; // V
          nv21Bytes[offset++] = image.planes[1].bytes[vuIndex]; // U
          // uvIndex += 2;
        }
      }

      return InputImage.fromBytes(
        bytes: nv21Bytes,
        metadata: InputImageMetadata(
          size: Size(width.toDouble(), height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: width,
        ),
      );
    }

    // iOS: BGRA8888 (1 plane)
    if (Platform.isIOS && image.format.group == ImageFormatGroup.bgra8888) {
      final bytes = image.planes[0].bytes;
      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.bgra8888,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
    }

    // Unsupported format
    // print('Unsupported camera image format: ${image.format.group}');
    return null;
  }
}
