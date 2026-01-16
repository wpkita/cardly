import 'package:flutter/material.dart';
import '../models/playing_card.dart';

class CardWidget extends StatelessWidget {
  final PlayingCard card;
  final bool isSelected;
  final VoidCallback? onTap;
  final double width;
  final double height;
  final bool faceDown;

  const CardWidget({
    super.key,
    required this.card,
    this.isSelected = false,
    this.onTap,
    this.width = 60,
    this.height = 90,
    this.faceDown = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: faceDown ? Colors.blue.shade800 : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.amber : Colors.black,
            width: isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: faceDown
            ? Center(
                child: Icon(
                  Icons.style,
                  color: Colors.white,
                  size: width * 0.5,
                ),
              )
            : _buildCardFace(),
      ),
    );
  }

  Widget _buildCardFace() {
    if (card.isJoker) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star,
              color: Colors.purple,
              size: width * 0.4,
            ),
            Text(
              'JOKER',
              style: TextStyle(
                fontSize: width * 0.15,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      );
    }

    final color = card.isRed ? Colors.red : Colors.black;

    return Stack(
      children: [
        Positioned(
          top: 4,
          left: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                card.rankSymbol,
                style: TextStyle(
                  fontSize: width * 0.25,
                  fontWeight: FontWeight.bold,
                  color: color,
                  height: 1,
                ),
              ),
              Text(
                card.suitSymbol,
                style: TextStyle(
                  fontSize: width * 0.25,
                  color: color,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
        Center(
          child: Text(
            card.suitSymbol,
            style: TextStyle(
              fontSize: width * 0.5,
              color: color.withOpacity(0.3),
            ),
          ),
        ),
        Positioned(
          bottom: 4,
          right: 4,
          child: Transform.rotate(
            angle: 3.14159,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.rankSymbol,
                  style: TextStyle(
                    fontSize: width * 0.25,
                    fontWeight: FontWeight.bold,
                    color: color,
                    height: 1,
                  ),
                ),
                Text(
                  card.suitSymbol,
                  style: TextStyle(
                    fontSize: width * 0.25,
                    color: color,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class CardStackWidget extends StatelessWidget {
  final List<PlayingCard> cards;
  final VoidCallback? onTap;
  final String label;
  final double cardWidth;
  final double cardHeight;
  final bool faceDown;

  const CardStackWidget({
    super.key,
    required this.cards,
    this.onTap,
    required this.label,
    this.cardWidth = 60,
    this.cardHeight = 90,
    this.faceDown = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            width: cardWidth,
            height: cardHeight,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: cards.isEmpty
                ? const Center(
                    child: Icon(Icons.close, color: Colors.grey),
                  )
                : Stack(
                    children: [
                      if (cards.length > 2)
                        Positioned(
                          left: 4,
                          top: 4,
                          child: CardWidget(
                            card: cards[cards.length - 3],
                            width: cardWidth,
                            height: cardHeight,
                            faceDown: faceDown,
                          ),
                        ),
                      if (cards.length > 1)
                        Positioned(
                          left: 2,
                          top: 2,
                          child: CardWidget(
                            card: cards[cards.length - 2],
                            width: cardWidth,
                            height: cardHeight,
                            faceDown: faceDown,
                          ),
                        ),
                      CardWidget(
                        card: cards.last,
                        width: cardWidth,
                        height: cardHeight,
                        faceDown: faceDown,
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            '${cards.length} cards',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
