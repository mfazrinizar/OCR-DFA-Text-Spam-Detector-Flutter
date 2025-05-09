# OCR DFA Text Spam Detector Flutter

A Flutter application that detects spam in text using DFA/NFA automata and OCR (Optical Character Recognition).

## Features

- **Spam Detection with DFA/NFA:**  
  Detects spam phrases using deterministic finite automata (DFA) built from a set of patterns. Patterns are compiled from NFA to DFA for fast substring matching.
- **Multi-pattern Support:**  
  Supports a list of spam patterns (see [`assets/spam.txt`](assets/spam.txt)).
- **OCR Integration:**  
  - **Manual Input:** Type text directly for spam detection.
  - **OCR Capture:** Extract text from images using the camera or gallery.
  - **Live OCR:** Real-time spam detection from live camera feed.
- **Automata Visualization:**  
  Visualize the DFA graph, including the path traversed for the current input.
- **Debounced Detection:**  
  Spam detection runs after 1 second of inactivity or when the detect icon is pressed.

## How It Works

1. **Pattern Compilation:**  
   Loads spam patterns from [`assets/spam.txt`](assets/spam.txt), builds an NFA for each, combines them, and converts to a DFA.
2. **Text Processing:**  
   For each input (typed or OCR), the DFA processes the text to detect if any spam pattern is present as a substring.
3. **OCR:**  
   Uses Google ML Kit for text recognition from images or live camera feed.
4. **Visualization:**  
   Shows the DFA structure and highlights the path for the current input.

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- Android/iOS device or emulator

### Installation

1. **Clone the repository:**
   ```sh
   git clone https://github.com/mfazrinizar/OCR-DFA-Text-Spam-Detector-Flutter
   cd OCR-DFA-Text-Spam-Detector-Flutter
   ```

2. **Install dependencies:**
   ```sh
   flutter pub get
   ```

3. **Run the app:**
   ```sh
   flutter run
   ```

### Assets

- **Spam Patterns:**  
  Edit [`assets/spam.txt`](assets/spam.txt) to add or remove spam phrases (one per line).

## Project Structure

```
lib/
  controllers/
    spam_detector_controller.dart
  models/
    spam_detector.dart
    dfa_state.dart
    nfa_state.dart
  utils/
    ocr_util.dart
  views/
    spam_detector_view.dart
    dfa_graph_view.dart
    nfa_graph_view.dart
    ocr_view.dart
assets/
  spam.txt
```

## Usage

1. **Select Input Mode:**  
   - Manual Input
   - OCR Capture (image)
   - OCR Live (camera)

2. **Enter or scan text.**  
   - For OCR, capture or upload an image, or use live camera.

3. **View Results:**  
   - The app will display whether the text is spam.
   - Optionally, view the DFA/NFA visualization.

## How the Spam Detection Works

- **Automata Theory:**  
  - Each spam pattern is compiled into an NFA.
  - All NFAs are combined and converted to a DFA.
  - The DFA is used to scan the input text for any substring that matches a spam pattern.
- **Efficient Matching:**  
  - The DFA approach ensures fast, linear-time matching for all patterns.
  - For advanced use, the Aho-Corasick algorithm can be used for even greater efficiency.

## Customization

- **Add/Remove Spam Patterns:**  
  Edit [`assets/spam.txt`](assets/spam.txt).
- **Change Detection Logic:**  
  Modify [`SpamDetectorModel`](lib/models/spam_detector.dart).
