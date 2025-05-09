import 'package:flutter/material.dart';
import '../models/spam_detector.dart';

enum InputType { manual, ocrCapture, ocrLive }

class SpamDetectorController extends ChangeNotifier {
  final SpamDetectorModel model;
  InputType inputType = InputType.manual;
  String inputText = '';
  bool isSpam = false;
  bool isLiveOcrActive = false;

  SpamDetectorController(this.model);

  void setInputType(InputType type) {
    inputType = type;
    notifyListeners();
  }

  void setInputText(String text) {
    inputText = text;
    isSpam = model.isSpam(text);
    notifyListeners();
  }

  void setOcrText(String text) {
    inputText = text;
    isSpam = model.isSpam(text);
    notifyListeners();
  }

  void startLiveOcr() {
    isLiveOcrActive = true;
    notifyListeners();
  }

  void stopLiveOcr() {
    isLiveOcrActive = false;
    notifyListeners();
  }

  List get dfaPath => model.getDfaPath(inputText);

  List get dfaStates => model.getStates();

  List get nfaStates => model.getNfaStates();

  get nfaStart => model.getNfaStartState();
}
