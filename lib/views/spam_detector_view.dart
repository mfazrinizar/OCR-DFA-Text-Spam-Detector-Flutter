import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:ocr_dfa_text_spam_detector/views/camera_view.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/spam_detector_controller.dart';
import '../models/dfa_state.dart';
import '../models/spam_detector.dart';
import '../utils/ocr_util.dart';
import 'dfa_graph_view.dart';
import 'ocr_view.dart';

class SpamDetectorView extends StatefulWidget {
  const SpamDetectorView({super.key});

  @override
  State<SpamDetectorView> createState() => _SpamDetectorViewState();
}

class _SpamDetectorViewState extends State<SpamDetectorView> {
  List<String>? _rules;

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  Future<void> _loadRules() async {
    final txt = await rootBundle.loadString('assets/spam.txt');
    setState(() {
      _rules = txt
          .split('\n')
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_rules == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return ChangeNotifierProvider(
      create: (_) => SpamDetectorController(
        SpamDetectorModel(_rules!),
      ),
      child: const SpamDetectorMainView(),
    );
  }
}

class SpamDetectorMainView extends StatefulWidget {
  const SpamDetectorMainView({super.key});

  @override
  State<SpamDetectorMainView> createState() => _SpamDetectorMainViewState();
}

class _SpamDetectorMainViewState extends State<SpamDetectorMainView> {
  late TextEditingController _controller;
  Timer? _debounce;
  String _pendingText = '';
  final StreamController<String> _ocrStreamController =
      StreamController<String>.broadcast();
  double _focusAreaWidth = 250;
  double _focusAreaHeight = 30;
  bool _showDFATree = false;

  @override
  void initState() {
    super.initState();
    final controller =
        Provider.of<SpamDetectorController>(context, listen: false);
    _controller = TextEditingController(text: controller.inputText);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _ocrStreamController.close();
    super.dispose();
  }

  void _onTextChanged(String text, SpamDetectorController controller) {
    _pendingText = text;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 1), () {
      controller.setInputText(_pendingText);
    });
  }

  void _onDetectPressed(SpamDetectorController controller) {
    _debounce?.cancel();
    controller.setInputText(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final controller = Provider.of<SpamDetectorController>(context);

    Widget focusAreaControls = Column(
      children: [
        Row(
          children: [
            const Text('Focus Width'),
            Expanded(
              child: Slider(
                min: 50,
                max: width,
                divisions: 14,
                value: _focusAreaWidth,
                label: _focusAreaWidth.round().toString(),
                onChanged: (v) => setState(() => _focusAreaWidth = v),
              ),
            ),
            Text('${_focusAreaWidth.round()} px'),
          ],
        ),
        Row(
          children: [
            const Text('Focus Height'),
            Expanded(
              child: Slider(
                min: 20,
                max: height * 0.5,
                divisions: 18,
                value: _focusAreaHeight,
                label: _focusAreaHeight.round().toString(),
                onChanged: (v) => setState(() => _focusAreaHeight = v),
              ),
            ),
            Text('${_focusAreaHeight.round()} px'),
          ],
        ),
      ],
    );

    Widget inputWidget;
    switch (controller.inputType) {
      case InputType.manual:
        inputWidget = TextField(
          maxLines: 5,
          minLines: 1,
          decoration: InputDecoration(
            labelText: 'Enter message',
            suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Detect',
              onPressed: () => _onDetectPressed(controller),
            ),
          ),
          controller: _controller,
          onChanged: (text) => _onTextChanged(text, controller),
        );
        break;
      case InputType.ocrCapture:
        inputWidget = Column(
          children: [
            FilledButton(
              onPressed: () async {
                final choice = await showModalBottomSheet<String>(
                  context: context,
                  builder: (context) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.camera_alt),
                        title: const Text('Open Camera'),
                        onTap: () => Navigator.pop(context, 'camera'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.photo_library),
                        title: const Text('Upload from Gallery'),
                        onTap: () => Navigator.pop(context, 'gallery'),
                      ),
                    ],
                  ),
                );
                if (context.mounted) {
                  if (choice == 'camera') {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CameraView(
                          onImageCaptured: (imagePath) async {
                            final text = await OCRUtil.extractTextFromImagePath(
                                imagePath);
                            if (mounted) {
                              setState(() {
                                _controller.text = text;
                              });
                              controller.setOcrText(text);
                            }
                          },
                        ),
                      ),
                    );
                  }
                } else if (choice == 'gallery') {
                  final picker = ImagePicker();
                  final picked =
                      await picker.pickImage(source: ImageSource.gallery);
                  if (picked == null) return;
                  final text =
                      await OCRUtil.extractTextFromImagePath(picked.path);
                  setState(() {
                    _controller.text = text;
                  });
                  controller.setOcrText(text);
                }
              },
              child: const Text('Image for OCR'),
            ),
            TextField(
              maxLines: 5,
              minLines: 1,
              decoration: InputDecoration(
                labelText: 'Extracted/Editable Text',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: 'Detect',
                  onPressed: () => _onDetectPressed(controller),
                ),
              ),
              controller: _controller,
              onChanged: (text) => _onTextChanged(text, controller),
            ),
          ],
        );
        break;
      case InputType.ocrLive:
        inputWidget = Column(
          children: [
            focusAreaControls,
            controller.isLiveOcrActive
                ? FilledButton(
                    onPressed: controller.stopLiveOcr,
                    child: const Text('Stop Live OCR'),
                  )
                : FilledButton(
                    onPressed: controller.startLiveOcr,
                    child: const Text('Start Live OCR'),
                  ),
            if (controller.isLiveOcrActive)
              SizedBox(
                height: height * 0.5,
                child: OCRView(
                  onScanText: (text) {
                    _ocrStreamController.add(text);
                  },
                  focusedAreaWidth: _focusAreaWidth,
                  focusedAreaHeight: _focusAreaHeight,
                ),
              ),
            StreamBuilder<String>(
              stream: _ocrStreamController.stream,
              builder: (context, snapshot) {
                final text = snapshot.data ?? '';
                if (_controller.text != text) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _controller.text = text;
                      _controller.selection =
                          TextSelection.collapsed(offset: text.length);
                      controller.setOcrText(text);
                    }
                  });
                }
                return TextField(
                  maxLines: 5,
                  minLines: 1,
                  decoration: InputDecoration(
                    labelText: 'Live OCR Text (Editable)',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      tooltip: 'Detect',
                      onPressed: () => _onDetectPressed(controller),
                    ),
                  ),
                  controller: _controller,
                  onChanged: (text) => _onTextChanged(text, controller),
                );
              },
            ),
          ],
        );
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR DFA-Optimized Spam Detector'),
        actions: [
          PopupMenuButton<InputType>(
            onSelected: (type) {
              _debounce?.cancel();
              setState(() {
                _controller.text = controller.inputText;
              });
              controller.setInputType(type);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: InputType.manual,
                child: Text('Manual Input'),
              ),
              const PopupMenuItem(
                value: InputType.ocrCapture,
                child: Text('OCR Capture / Input Image'),
              ),
              const PopupMenuItem(
                value: InputType.ocrLive,
                child: Text('OCR Live Capture'),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: SingleChildScrollView(
          child: Column(
            children: [
              inputWidget,
              const SizedBox(height: 10),
              Text(
                controller.isSpam ? 'Detected as SPAM' : 'Not Spam',
                style: TextStyle(
                  fontSize: 20,
                  color: controller.isSpam ? Colors.red : Colors.green,
                ),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Show DFA Tree',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Switch(
                    value: _showDFATree,
                    onChanged: (val) {
                      setState(() {
                        _showDFATree = val;
                      });
                    },
                  ),
                ],
              ),
              if (_showDFATree) ...[
                Text(
                  'DFA Tree',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                SizedBox(
                  height: height * 0.75,
                  child: DFAGraphView(
                    dfaStates: controller.dfaStates.cast<DFAState>(),
                    dfaPath: controller.dfaPath.cast<DFAState>(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
