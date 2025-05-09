import 'nfa_state.dart';

class DFAState {
  final int id;
  final bool isAccept;
  final Map<String, DFAState> transitions = {};
  DFAState(this.id, this.isAccept);
}

List<DFAState> convertNfaToDfa(NFAState nfaStart) {
  var alphabet = <String>{};
  void collectAlphabet(NFAState s, Set<NFAState> seen) {
    if (!seen.add(s)) return;
    for (var entry in s.transitions.entries) {
      var sym = entry.key;
      if (sym != null) alphabet.add(sym);
      for (var t in entry.value) {
        collectAlphabet(t, seen);
      }
    }
  }

  collectAlphabet(nfaStart, {});

  var startClosure = epsilonClosure({nfaStart});
  var stateMap = <Set<NFAState>, DFAState>{};
  var queue = <Set<NFAState>>[];

  bool isAccepting(Set<NFAState> s) => s.any((x) => x.isAccept);

  var startDfa = DFAState(0, isAccepting(startClosure));
  stateMap[startClosure] = startDfa;
  queue.add(startClosure);

  while (queue.isNotEmpty) {
    var currentSet = queue.removeAt(0);
    var currentDfa = stateMap[currentSet]!;
    for (var sym in alphabet) {
      var moved = move(currentSet, sym);
      if (moved.isEmpty) continue;
      var closure = epsilonClosure(moved);
      var dfaState = stateMap[closure];
      if (dfaState == null) {
        dfaState = DFAState(stateMap.length, isAccepting(closure));
        stateMap[closure] = dfaState;
        queue.add(closure);
      }
      currentDfa.transitions[sym] = dfaState;
    }
  }

  return stateMap.values.toList();
}
