import 'package:flutter/material.dart';
import '../../models/tile.dart';
import 'tile_widget.dart';
import 'drag_data.dart';

class RackWidget extends StatelessWidget {
  final List<Tile> tiles;
  final VoidCallback onSortByRuns;
  final VoidCallback onSortByGroups;
  final Function(DragData data) onReturnTileToHand;

  const RackWidget({
    super.key,
    required this.tiles,
    required this.onSortByRuns,
    required this.onSortByGroups,
    required this.onReturnTileToHand,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1F13), // Deep wood brown color
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header / Controls Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Seu Suporte',
                style: TextStyle(
                  color: Color(0xFFE5D5C5),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF423220),
                      foregroundColor: const Color(0xFFE5D5C5),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    icon: const Icon(Icons.sort, size: 14),
                    label: const Text('Por Sequência', style: TextStyle(fontSize: 11)),
                    onPressed: onSortByRuns,
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF423220),
                      foregroundColor: const Color(0xFFE5D5C5),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    icon: const Icon(Icons.grid_view, size: 14),
                    label: const Text('Por Grupo', style: TextStyle(fontSize: 11)),
                    onPressed: onSortByGroups,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Horizontal scrolling 2-tier rack as a DragTarget
          DragTarget<DragData>(
            onWillAccept: (data) => data != null && data.source == 'board',
            onAccept: (data) {
              onReturnTileToHand(data);
            },
            builder: (context, candidateData, rejectedData) {
              final isOver = candidateData.isNotEmpty;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 145,
                decoration: BoxDecoration(
                  color: isOver ? Colors.white.withOpacity(0.08) : Colors.black12,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isOver ? const Color(0xFFE5D5C5) : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: tiles.isEmpty
                    ? const Center(
                        child: Text(
                          'Sem peças! Você venceu?',
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    : GridView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.all(8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 1.35, // Dimensions for Tile (44x60)
                        ),
                        itemCount: tiles.length,
                        itemBuilder: (context, index) {
                          final tile = tiles[index];
                          return Draggable<DragData>(
                            data: DragData(
                              tile: tile,
                              source: 'rack',
                            ),
                            feedback: Material(
                              color: Colors.transparent,
                              child: Opacity(
                                opacity: 0.8,
                                child: TileWidget(tile: tile, width: 44, height: 60),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.2,
                              child: TileWidget(tile: tile, width: 44, height: 60),
                            ),
                            child: TileWidget(tile: tile, width: 44, height: 60),
                          );
                        },
                      ),
              );
            },
          ),
        ],
      ),
    );
  }
}
