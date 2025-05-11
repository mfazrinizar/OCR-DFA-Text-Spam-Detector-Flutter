import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/spam_detector_controller.dart';
import '../utils/ocr_util.dart';
import 'camera_view.dart';
import 'dfa_graph_view.dart';

class OCRImageInputView extends StatefulWidget {
  const OCRImageInputView({super.key});

  @override
  State<OCRImageInputView> createState() => _OCRImageInputViewState();
}

class _OCRImageInputViewState extends State<OCRImageInputView> {
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
    _controller.dispose();
    super.dispose();
  }

  void _onDetectPressed(SpamDetectorController controller) {
    controller.setInputText(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<SpamDetectorController>(context);
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        title: const Text('Image Input OCR'),
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
                              final text =
                                  await OCRUtil.extractTextFromImagePath(
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
                onChanged: (text) => controller.setInputText(text),
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
