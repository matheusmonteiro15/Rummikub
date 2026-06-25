import 'package:flutter/material.dart';
import '../../models/tile.dart';

class TileWidget extends StatelessWidget {
  final Tile tile;
  final double width;
  final double height;
  final bool isSelected;
  final VoidCallback? onTap;

  const TileWidget({
    super.key,
    required this.tile,
    this.width = 44.0,
    this.height = 60.0,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color textColor;
    String displayVal;

    if (tile.isJoker) {
      textColor = Colors.deepOrange;
      displayVal = '🃏';
    } else {
      displayVal = tile.number.toString();
      switch (tile.color!) {
        case TileColor.red:
          textColor = const Color(0xFFD32F2F); // Vibrant Red
          break;
        case TileColor.blue:
          textColor = const Color(0xFF1976D2); // Vibrant Blue
          break;
        case TileColor.yellow:
          textColor = const Color(0xFFF57C00); // Darker Amber/Orange for high readability
          break;
        case TileColor.black:
          textColor = const Color(0xFF212121); // Charcoal Black
          break;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFFCFBF7), // Ivory color
          borderRadius: BorderRadius.circular(6.0),
          border: Border.all(
            color: isSelected ? Colors.orangeAccent : const Color(0xFFE5E2D9),
            width: isSelected ? 2.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 4.0,
              offset: const Offset(1, 2),
            ),
            // Inner bevel effect
            const BoxShadow(
              color: Color(0x33FFFFFF),
              blurRadius: 0.0,
              offset: Offset(1, 1),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Subtly colored border indicator on the bottom of normal tiles
            if (!tile.isJoker)
              Positioned(
                left: 6,
                right: 6,
                bottom: 4,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: textColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            // The number or Joker symbol
            Center(
              child: tile.isJoker
                  ? Text(
                      displayVal,
                      style: TextStyle(
                        fontSize: height * 0.5,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : Text(
                      displayVal,
                      style: TextStyle(
                        color: textColor,
                        fontSize: height * 0.45,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Roboto',
                        height: 1.0,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
