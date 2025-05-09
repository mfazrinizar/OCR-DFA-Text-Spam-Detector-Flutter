import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import '../models/nfa_state.dart';

class NFAGraphView extends StatelessWidget {
  final List<NFAState> nfaStates;
  final NFAState nfaStart;

  const NFAGraphView({
    super.key,
    required this.nfaStates,
    required this.nfaStart,
  });

  @override
  Widget build(BuildContext context) {
    final graph = Graph();
    final nodeMap = {for (var s in nfaStates) s: Node.Id(s.id)};

    for (var s in nfaStates) {
      var node = nodeMap[s]!;
      graph.addNode(node);
      s.transitions.forEach((sym, targets) {
        for (var t in targets) {
          graph.addEdge(
            node,
            nodeMap[t]!,
            paint: Paint()
              ..color = sym == null ? Colors.blue : Colors.black
              ..strokeWidth = sym == null ? 2 : 1,
          );
        }
      });
    }

    final config = BuchheimWalkerConfiguration()
      ..siblingSeparation = 50
      ..levelSeparation = 100
      ..subtreeSeparation = 100
      ..orientation = BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM;

    return InteractiveViewer(
      constrained: false,
      boundaryMargin: const EdgeInsets.all(100),
      minScale: 0.01,
      maxScale: 5.0,
      child: GraphView(
        graph: graph,
        algorithm: BuchheimWalkerAlgorithm(config, TreeEdgeRenderer(config)),
        builder: (Node node) {
          final state = nfaStates.firstWhere((s) => s.id == node.key!.value);
          final isStart = state == nfaStart;
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isStart ? Colors.orangeAccent : Colors.white,
              border: Border.all(
                color: state.isAccept ? Colors.green : Colors.black,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'q${state.id}',
              style: TextStyle(
                color: isStart ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
    );
  }
}
