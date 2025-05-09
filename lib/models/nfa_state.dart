class NFAState {
  final int id;
  final Map<String?, List<NFAState>> transitions = {};
  bool isAccept = false;
  NFAState(this.id);
  void addTransition(String? symbol, NFAState to) {
    transitions.putIfAbsent(symbol, () => []).add(to);
  }
}

NFAState buildLiteralNFA(String pattern, List<NFAState> collector) {
  var start = NFAState(collector.length);
  collector.add(start);
  var current = start;
  for (var ch in pattern.split('')) {
    var next = NFAState(collector.length);
    collector.add(next);
    current.addTransition(ch, next);
    current = next;
  }
  current.isAccept = true;
  return start;
}

NFAState combineNFAs(List<NFAState> starts, List<NFAState> collector) {
  var newStart = NFAState(collector.length);
  collector.add(newStart);
  for (var s in starts) {
    newStart.addTransition(null, s);
  }
  return newStart;
}

Set<NFAState> epsilonClosure(Set<NFAState> states) {
  var closure = Set<NFAState>.from(states);
  var stack = List<NFAState>.from(states);
  while (stack.isNotEmpty) {
    var s = stack.removeLast();
    for (var next in s.transitions[null] ?? []) {
      if (closure.add(next)) stack.add(next);
    }
  }
  return closure;
}

Set<NFAState> move(Set<NFAState> states, String symbol) {
  var result = <NFAState>{};
  for (var s in states) {
    for (var next in s.transitions[symbol] ?? []) {
      result.add(next);
    }
  }
  return result;
}
