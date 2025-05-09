import 'dfa_state.dart';
import 'nfa_state.dart';

class SpamDetectorModel {
  late List<DFAState> dfaStates;
  late DFAState dfaStart;
  late List<NFAState> nfaStates;
  late NFAState nfaStart;
  final List<String> patterns;

  SpamDetectorModel(this.patterns) {
    nfaStates = <NFAState>[];
    var starts = <NFAState>[];
    for (var pat in patterns) {
      starts.add(buildLiteralNFA(pat, nfaStates));
    }
    nfaStart = combineNFAs(starts, nfaStates);
    dfaStates = convertNfaToDfa(nfaStart);
    dfaStart = dfaStates.first;
  }

  bool isSpam(String text) {
    text = text.toLowerCase();
    for (int i = 0; i < text.length; i++) {
      var state = dfaStart;
      for (int j = i; j < text.length; j++) {
        var ch = text[j];
        state = state.transitions[ch] ?? dfaStart;
        if (state.isAccept) {
          return true;
        }
      }
    }
    return false;
  }

  List<DFAState> getStates() => dfaStates;

  DFAState getStartState() => dfaStart;

  List<DFAState> getDfaPath(String text) {
    var path = <DFAState>[];
    var state = dfaStart;
    path.add(state);
    for (var ch in text.split('')) {
      state = state.transitions[ch] ?? state;
      path.add(state);
    }
    return path;
  }

  List<NFAState> getNfaStates() => nfaStates;
  NFAState getNfaStartState() => nfaStart;
}

class Range {
  final int start;
  final int end;
  Range(this.start, this.end);
}
