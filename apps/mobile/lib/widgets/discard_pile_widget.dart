import 'package:flutter/material.dart';

import '../models/playing_card.dart';
import 'card_widget.dart';

class DiscardPileWidget extends StatelessWidget {
  const DiscardPileWidget({
    required this.discardPile,
    super.key,
    this.onDiscardTap,
    this.selectedIndex,
  });
  final List<PlayingCard> discardPile;
  final Function(int)? onDiscardTap;
  final int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Discard Pile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          height: 150,
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade100,
          ),
          child: discardPile.isEmpty
              ? const Center(child: Text('Empty'))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Row(
                    children: List.generate(
                      discardPile.length > 10 ? 10 : discardPile.length,
                      (index) {
                        final actualIndex = discardPile.length - 10 + index >= 0
                            ? discardPile.length - 10 + index
                            : index;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: CardWidget(
                            card: discardPile[actualIndex],
                            isSelected: selectedIndex == actualIndex,
                            onTap: onDiscardTap != null
                                ? () => onDiscardTap!(actualIndex)
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ),
        ),
        if (discardPile.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${discardPile.length} cards',
              style: const TextStyle(fontSize: 12),
            ),
          ),
      ],
    );
  }
}
