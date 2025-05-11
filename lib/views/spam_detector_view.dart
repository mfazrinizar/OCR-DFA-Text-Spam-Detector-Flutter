import 'package:flutter/material.dart';
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:provider/provider.dart';
import '../controllers/spam_detector_controller.dart';
import '../models/spam_detector.dart';
import 'manual_input_view.dart';
import 'ocr_image_input_view.dart';
import 'ocr_live_capture_view.dart';

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
    final txt = await DefaultAssetBundle.of(context)
        .loadString('assets/spam-sample.txt');
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
      child: const SpamDetectorMenuView(),
    );
  }
}

class SpamDetectorMenuView extends StatefulWidget {
  const SpamDetectorMenuView({super.key});

  @override
  State<SpamDetectorMenuView> createState() => _SpamDetectorMenuViewState();
}

class _SpamDetectorMenuViewState extends State<SpamDetectorMenuView> {
  late final NotchBottomBarController _controller;
  late final PageController _pageController;

  final List<Widget> _pages = const [
    ManualInputView(),
    OCRImageInputView(),
    OCRLiveCaptureView(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _controller = NotchBottomBarController(index: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _pages,
      ),
      extendBody: true,
      bottomNavigationBar: AnimatedNotchBottomBar(
        durationInMilliSeconds: 300,
        kIconSize: 24.0,
        kBottomRadius: 28.0,
        notchBottomBarController: _controller,
        color: Colors.lightBlueAccent,
        notchColor: Colors.lightBlue,
        showLabel: false,
        removeMargins: false,
        bottomBarItems: const [
          BottomBarItem(
            inActiveItem: Icon(Icons.keyboard, color: Colors.white),
            activeItem: Icon(Icons.keyboard, color: Colors.white),
            itemLabel: 'Manual Input',
          ),
          BottomBarItem(
            inActiveItem: Icon(Icons.image, color: Colors.white),
            activeItem: Icon(Icons.image, color: Colors.white),
            itemLabel: 'Image OCR',
          ),
          BottomBarItem(
            inActiveItem: Icon(Icons.videocam, color: Colors.white),
            activeItem: Icon(Icons.video_call, color: Colors.white),
            itemLabel: 'Live OCR',
          ),
        ],
        onTap: (index) {
          _pageController.jumpToPage(index);
        },
      ),
    );
  }
}
