import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/spam_detector_controller.dart';
import 'ocr_view.dart';
import 'dfa_graph_view.dart';

class OCRLiveCaptureView extends StatefulWidget {
  const OCRLiveCaptureView({super.key});

  @override
  State<OCRLiveCaptureView> createState() => _OCRLiveCaptureViewState();
}

class _OCRLiveCaptureViewState extends State<OCRLiveCaptureView> {
  final StreamController<String> _ocrStreamController =
      StreamController<String>.broadcast();
  double _focusAreaWidth = 250;
  double _focusAreaHeight = 30;
  late TextEditingController _controller;
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
    _ocrStreamController.close();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final controller = Provider.of<SpamDetectorController>(context);

    Widget focusAreaControls = Column(
      children: [
        Row(
          children: [
            const Text('Focus Width'),
            Expanded(
              child: Slider(
                min: 50,
                max: MediaQuery.of(context).size.width,
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

    return Scaffold(
      appBar: AppBar(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        title: const Text('Live Capture OCR'),
        actions: [
          ClipOval(
            child: TextButton.icon(
              label: const Text('Clear Text'),
              icon: const Icon(Icons.clear),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                _controller.clear();
                controller.setInputText('');
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
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
                        onPressed: () =>
                            controller.setInputText(_controller.text),
                      ),
                    ),
                    controller: _controller,
                    onChanged: (text) => controller.setInputText(text),
                  );
                },
              ),
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
                  Text('Show DFA Tree',
                      style: Theme.of(context).textTheme.titleMedium),
                  Switch(
                    value: _showDFATree,
                    onChanged: (val) => setState(() => _showDFATree = val),
                  ),
                ],
              ),
              if (_showDFATree)
                SizedBox(
                  height: height * 0.75,
                  child: DFAGraphView(
                    dfaStates: controller.dfaStates.cast(),
                    dfaPath: controller.dfaPath.cast(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
