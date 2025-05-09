import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import '../models/dfa_state.dart';

class DFAGraphView extends StatelessWidget {
  final List<DFAState> dfaStates;
  final List<DFAState> dfaPath;

  const DFAGraphView({
    super.key,
    required this.dfaStates,
    required this.dfaPath,
  });

  @override
  Widget build(BuildContext context) {
    final graph = Graph();
    final nodeMap = {for (var s in dfaStates) s: Node.Id(s.id)};
    final pathSet = dfaPath.toSet();

    for (var s in dfaStates) {
      var node = nodeMap[s]!;
      graph.addNode(node);
      s.transitions.forEach((sym, t) {
        final isOnPath = pathSet.contains(s) && pathSet.contains(t);
        graph.addEdge(
          node,
          nodeMap[t]!,
          paint: Paint()
            ..color = isOnPath ? Colors.red : Colors.black
            ..strokeWidth = isOnPath ? 3 : 1,
        );
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
          final state = dfaStates.firstWhere((s) => s.id == node.key!.value);
          final isOnPath = dfaPath.contains(state);
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isOnPath ? Colors.redAccent : Colors.white,
              border: Border.all(
                color: state.isAccept ? Colors.green : Colors.black,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'q${state.id}',
              style: TextStyle(
                color: isOnPath ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
    );
  }
}
