import 'package:flutter/material.dart';
import '../models/playing_card.dart';
import 'card_widget.dart';

class PlayerHand extends StatelessWidget {
  final List<PlayingCard> hand;
  final List<int> selectedIndices;
  final Function(int) onCardTap;
  final bool isCurrentPlayer;

  const PlayerHand({
    super.key,
    required this.hand,
    required this.selectedIndices,
    required this.onCardTap,
    this.isCurrentPlayer = true,
  });

  @override
  Widget build(BuildContext context) {
    if (hand.isEmpty) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        child: const Text('No cards in hand'),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: hand.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: CardWidget(
              card: hand[index],
              isSelected: selectedIndices.contains(index),
              onTap: isCurrentPlayer ? () => onCardTap(index) : null,
              width: 70,
              height: 100,
            ),
          );
        },
      ),
    );
  }
}
