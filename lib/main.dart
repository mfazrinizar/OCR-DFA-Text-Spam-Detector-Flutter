import 'package:flutter/material.dart';
import 'package:ocr_dfa_text_spam_detector/views/spam_detector_view.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Spam Detector",
      theme: ThemeData(useMaterial3: false),
      home: const SpamDetectorView(),
    );
  }
}
