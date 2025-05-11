import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/spam_detector_controller.dart';
import 'dfa_graph_view.dart';

class ManualInputView extends StatefulWidget {
  const ManualInputView({super.key});

  @override
  State<ManualInputView> createState() => _ManualInputViewState();
}

class _ManualInputViewState extends State<ManualInputView> {
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
        title: const Text('Manual Input'),
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
              TextField(
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
