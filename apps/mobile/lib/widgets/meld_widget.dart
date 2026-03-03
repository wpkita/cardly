import 'package:flutter/material.dart';

import '../models/rummy_game_state.dart';
import 'card_widget.dart';

class MeldWidget extends StatelessWidget {
  const MeldWidget({
    required this.meld,
    required this.playerIndex,
    required this.meldIndex,
    super.key,
    this.onCardTap,
  });
  final Meld meld;
  final int playerIndex;
  final int meldIndex;
  final Function(int, int)? onCardTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green),
        borderRadius: BorderRadius.circular(8),
        color: Colors.green.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                meld.type == MeldType.set ? 'Set' : 'Run',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                '${meld.points} pts',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: meld.cards.length,
              itemBuilder: (context, cardIndex) {
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: CardWidget(
                    card: meld.cards[cardIndex],
                    width: 50,
                    height: 70,
                    onTap: onCardTap != null
                        ? () => onCardTap!(playerIndex, meldIndex)
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class MeldsDisplay extends StatelessWidget {
  const MeldsDisplay({
    required this.melds,
    required this.playerName,
    required this.playerIndex,
    super.key,
    this.onMeldTap,
  });
  final List<Meld> melds;
  final String playerName;
  final int playerIndex;
  final Function(int, int)? onMeldTap;

  @override
  Widget build(BuildContext context) {
    if (melds.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(8),
        child: Text(
          '$playerName has no melds',
          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$playerName\'s Melds',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...melds.asMap().entries.map((entry) {
          return MeldWidget(
            meld: entry.value,
            playerIndex: playerIndex,
            meldIndex: entry.key,
            onCardTap: onMeldTap,
          );
        }),
      ],
    );
  }
}
