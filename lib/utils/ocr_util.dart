import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRUtil {
  static Future<String> extractTextFromImagePath(String path) async {
    final inputImage = InputImage.fromFilePath(path);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final recognizedText = await textRecognizer.processImage(inputImage);
    await textRecognizer.close();
    return recognizedText.text;
  }
}
