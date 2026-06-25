import 'package:flutter/material.dart';
import '../../models/board.dart';
import '../../models/meld.dart';
import '../../models/tile.dart';
import 'tile_widget.dart';
import 'drag_data.dart';

class BoardWidget extends StatelessWidget {
  final Board board;
  final Function(DragData data, int toMeldIdx, int toTileIdx) onTileDropped;
  final Function(int meldIdx, int splitIdx)? onSplitMeld;

  const BoardWidget({
    super.key,
    required this.board,
    required this.onTileDropped,
    this.onSplitMeld,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D5C46), // Felt Green
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Table markings
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: GridPaper(
                color: Colors.white,
                divisions: 1,
                subdivisions: 1,
                interval: 100,
              ),
            ),
          ),
          board.melds.isEmpty
              ? _buildEmptyBoardMessage()
              : _buildMeldsList(),
        ],
      ),
    );
  }

  Widget _buildEmptyBoardMessage() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.style, size: 48, color: Colors.white60),
          const SizedBox(height: 12),
          const Text(
            'Mesa Vazia',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Arraste peças aqui para criar uma combinação\n(Mínimo de 30 pontos na primeira jogada)',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white38,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          // Giant drag target to create the first meld
          _buildNewMeldTarget(height: 120),
        ],
      ),
    );
  }

  Widget _buildMeldsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: board.melds.length + 1, // +1 for the "Create New Meld" target
      itemBuilder: (context, index) {
        if (index == board.melds.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: _buildNewMeldTarget(height: 70),
          );
        }

        final meld = board.melds[index];
        return _buildMeldRow(meld, index);
      },
    );
  }

  Widget _buildMeldRow(Meld meld, int meldIdx) {
    final bool isValid = meld.isValid;

    return DragTarget<DragData>(
      onWillAccept: (data) => data != null,
      onAccept: (data) {
        // Se soltar na linha, adiciona ao final do grupo/sequência
        onTileDropped(data, meldIdx, meld.tiles.length);
      },
      builder: (context, candidateData, rejectedData) {
        final isOver = candidateData.isNotEmpty;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: isOver 
                ? Colors.white.withOpacity(0.15) 
                : (isValid ? Colors.black26 : Colors.red.withOpacity(0.12)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isOver 
                  ? Colors.white54 
                  : (isValid ? Colors.white24 : Colors.red.withOpacity(0.5)),
              width: isOver ? 1.5 : (isValid ? 1.0 : 1.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Meld header with status and points
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    meld.type == MeldType.run
                        ? 'Sequência'
                        : meld.type == MeldType.group
                            ? 'Grupo'
                            : 'Combinação Inválida',
                    style: TextStyle(
                      color: isValid ? Colors.white60 : Colors.redAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isValid)
                    Text(
                      '${meld.points} pts',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              // Horizontal list of tiles with drop targets between them
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _buildTilesWithDropTargets(meld, meldIdx),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildTilesWithDropTargets(Meld meld, int meldIdx) {
    final List<Widget> widgets = [];

    // Drop target before the first tile
    widgets.add(_buildInBetweenDropTarget(meldIdx, 0));

    for (int i = 0; i < meld.tiles.length; i++) {
      final tile = meld.tiles[i];

      // The draggable tile itself
      widgets.add(
        Draggable<DragData>(
          data: DragData(
            tile: tile,
            source: 'board',
            fromMeldIdx: meldIdx,
            fromTileIdx: i,
          ),
          feedback: Material(
            color: Colors.transparent,
            child: Opacity(
              opacity: 0.75,
              child: TileWidget(tile: tile, width: 40, height: 55),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: TileWidget(tile: tile, width: 40, height: 55),
          ),
          child: TileWidget(tile: tile, width: 40, height: 55),
        ),
      );

      // Scissor/Split button between tiles (if supported and long enough to split)
      if (onSplitMeld != null && i < meld.tiles.length - 1 && meld.tiles.length >= 2) {
        widgets.add(
          IconButton(
            icon: const Icon(Icons.content_cut, size: 14, color: Colors.white30),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
            tooltip: 'Dividir aqui',
            onPressed: () => onSplitMeld!(meldIdx, i + 1),
          ),
        );
      } else {
        // Drop target after this tile
        widgets.add(_buildInBetweenDropTarget(meldIdx, i + 1));
      }
    }

    return widgets;
  }

  Widget _buildInBetweenDropTarget(int meldIdx, int tileIdx) {
    return DragTarget<DragData>(
      onWillAccept: (data) => data != null,
      onAccept: (data) {
        onTileDropped(data, meldIdx, tileIdx);
      },
      builder: (context, candidateData, rejectedData) {
        final isOver = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: isOver ? 35 : 12,
          height: 50,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isOver ? Colors.white30 : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: isOver ? Border.all(color: Colors.white, width: 1.5) : null,
          ),
          child: const Center(
            child: Icon(Icons.add, size: 12, color: Colors.white70),
          ),
        );
      },
    );
  }

  Widget _buildNewMeldTarget({required double height}) {
    return DragTarget<DragData>(
      onWillAccept: (data) => data != null,
      onAccept: (data) {
        onTileDropped(data, -1, -1);
      },
      builder: (context, candidateData, rejectedData) {
        final isOver = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isOver ? Colors.white24 : Colors.white10,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isOver ? Colors.white70 : Colors.white30,
              width: 1.5,
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline, color: Colors.white54, size: 24),
                SizedBox(height: 6),
                Text(
                  'Criar Nova Combinação',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
