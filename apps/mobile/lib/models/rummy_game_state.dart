import 'playing_card.dart';

enum MeldType { set, run }

class Meld {
  Meld({required this.cards, required this.type});
  final List<PlayingCard> cards;
  final MeldType type;

  /// Returns the total point value of this meld.
  /// For runs, Ace is scored as 1 point if low (A-2-3) or 15 if high (Q-K-A).
  int get points {
    if (type == MeldType.run) {
      return cards.fold(0, (sum, card) {
        if (card.rank == Rank.ace) {
          // Check if ace is used as low (A-2-3) or high (Q-K-A)
          final hasTwo = cards.any((c) => c.rank == Rank.two);
          final hasKing = cards.any((c) => c.rank == Rank.king);
          return sum + card.points(aceHigh: hasKing && !hasTwo);
        }
        return sum + card.points();
      });
    }
    return cards.fold(0, (sum, card) => sum + card.points());
  }

  bool isValid() {
    if (cards.length < 3) return false;

    if (type == MeldType.set) {
      return _isValidSet();
    } else {
      return _isValidRun();
    }
  }

  bool _isValidSet() {
    if (cards.isEmpty) return false;
    final rank = cards.first.rank;
    final suits = <Suit>{};

    for (final card in cards) {
      if (card.rank != rank) return false;
      suits.add(card.suit);
    }

    // All cards must be same rank with different suits
    return suits.length == cards.length && cards.length <= 4;
  }

  bool _isValidRun() {
    if (cards.isEmpty) return false;

    // All cards must be the same suit
    final suit = cards.first.suit;
    for (final card in cards) {
      if (card.suit != suit) return false;
    }

    // Get rank indices
    final rankIndices = cards.map((c) => c.rank.index).toList();
    rankIndices.sort();

    // Check for ace (index 0) - it can be high (after king) or low (before 2)
    final hasAce = rankIndices.contains(0);
    final hasKing = rankIndices.contains(12); // King is index 12
    final hasTwo = rankIndices.contains(1); // Two is index 1

    if (hasAce) {
      // If ace is present with king but no two, treat ace as high (index 13)
      if (hasKing && !hasTwo) {
        // Try ace-high sequence (e.g., Q-K-A)
        final aceHighIndices = rankIndices.map((i) => i == 0 ? 13 : i).toList();
        aceHighIndices.sort();
        if (_isConsecutive(aceHighIndices)) return true;
      }
      // If ace is present with two but no king, treat ace as low (index 0)
      if (hasTwo && !hasKing) {
        // Try ace-low sequence (e.g., A-2-3)
        if (_isConsecutive(rankIndices)) return true;
      }
      // If ace is present with both king and two, it's invalid (no wrap-around)
      if (hasKing && hasTwo) return false;
      // If ace is alone or with neither king nor two, check as low
      if (!hasKing && !hasTwo) {
        if (_isConsecutive(rankIndices)) return true;
      }
    } else {
      // No ace, just check consecutive
      if (_isConsecutive(rankIndices)) return true;
    }

    return false;
  }

  bool _isConsecutive(List<int> indices) {
    for (var i = 1; i < indices.length; i++) {
      if (indices[i] != indices[i - 1] + 1) return false;
    }
    return true;
  }
}

enum GamePhase { draw, play, discard }

class Player {
  Player({
    required this.name,
    List<PlayingCard>? hand,
    List<Meld>? melds,
    this.score = 0,
  }) : hand = hand ?? [],
       melds = melds ?? [];
  final String name;
  final List<PlayingCard> hand;
  final List<Meld> melds;
  int score;

  int get handPoints {
    return hand.fold(0, (sum, card) => sum + card.points());
  }

  int get meldPoints {
    return melds.fold(0, (sum, meld) => sum + meld.points);
  }

  void sortHand() {
    hand.sort((a, b) {
      if (a.suit.index != b.suit.index) {
        return a.suit.index.compareTo(b.suit.index);
      }
      return a.rank.index.compareTo(b.rank.index);
    });
  }
}

class RummyGameState {
  RummyGameState({
    required this.deck,
    required this.discardPile,
    required this.players,
    this.currentPlayerIndex = 0,
    this.currentPhase = GamePhase.draw,
    this.drawnCard,
    this.selectedDiscardIndex,
    List<int>? selectedHandIndices,
    this.message,
    this.mustUseCard,
    List<PlayingCard>? cardsDrawnFromDiscard,
  })  : selectedHandIndices = selectedHandIndices ?? [],
        cardsDrawnFromDiscard = cardsDrawnFromDiscard ?? [];
  final Deck deck;
  final List<PlayingCard> discardPile;
  final List<Player> players;
  int currentPlayerIndex;
  GamePhase currentPhase;
  PlayingCard? drawnCard;
  int? selectedDiscardIndex;
  List<int> selectedHandIndices;
  String? message;
  /// When drawing from discard pile, this card must be used immediately
  /// (melded or laid off) before the player can discard.
  PlayingCard? mustUseCard;
  /// Cards drawn from the discard pile (for undo functionality)
  List<PlayingCard> cardsDrawnFromDiscard;

  Player get currentPlayer => players[currentPlayerIndex];

  bool get isGameOver => players.any((p) => p.score >= 500);

  void dealCards() {
    // Deal 7 cards per player normally, 13 cards in 2-player game
    final cardsPerPlayer = players.length == 2 ? 13 : 7;

    for (var i = 0; i < cardsPerPlayer; i++) {
      for (final player in players) {
        final card = deck.draw();
        if (card != null) {
          player.hand.add(card);
        }
      }
    }

    final firstDiscard = deck.draw();
    if (firstDiscard != null) {
      discardPile.add(firstDiscard);
    }

    for (final player in players) {
      player.sortHand();
    }
  }

  void drawFromDeck() {
    if (currentPhase != GamePhase.draw) return;

    final card = deck.draw();
    if (card != null) {
      drawnCard = card;
      currentPlayer.hand.add(card);
      currentPlayer.sortHand();
      currentPhase = GamePhase.play;
      message = 'Drew a card from deck. Play melds or discard.';
    }
  }

  void drawFromDiscard(int discardIndex) {
    if (currentPhase != GamePhase.draw) return;
    if (discardPile.isEmpty) return;
    if (discardIndex < 0 || discardIndex >= discardPile.length) return;

    // The selected card that must be immediately used
    final selectedCard = discardPile[discardIndex];
    mustUseCard = selectedCard;

    // Track the cards drawn for undo functionality
    cardsDrawnFromDiscard.clear();
    for (var i = discardIndex; i < discardPile.length; i++) {
      cardsDrawnFromDiscard.add(discardPile[i]);
    }

    // Take all cards from the selected one to the top
    for (var i = discardPile.length - 1; i >= discardIndex; i--) {
      currentPlayer.hand.add(discardPile[i]);
    }

    discardPile.removeRange(discardIndex, discardPile.length);
    currentPlayer.sortHand();
    currentPhase = GamePhase.play;
    message = 'Drew from discard pile. You must use ${selectedCard.rankSymbol}${selectedCard.suitSymbol} in a meld!';
  }

  /// Undo drawing from discard pile and restart the turn.
  /// Only available if mustUseCard is set (drew from discard but haven't used it).
  bool undoDiscardDraw() {
    if (mustUseCard == null || cardsDrawnFromDiscard.isEmpty) {
      message = 'Nothing to undo!';
      return false;
    }

    // Remove the drawn cards from hand
    for (final card in cardsDrawnFromDiscard) {
      currentPlayer.hand.remove(card);
    }

    // Put them back on the discard pile in original order
    discardPile.addAll(cardsDrawnFromDiscard);

    // Reset state
    cardsDrawnFromDiscard.clear();
    mustUseCard = null;
    currentPhase = GamePhase.draw;
    selectedHandIndices.clear();
    message = 'Turn restarted. Draw a card.';
    return true;
  }

  bool playMeld(List<int> cardIndices, MeldType type) {
    if (currentPhase != GamePhase.play) return false;
    if (cardIndices.length < 3) return false;

    final cards = cardIndices.map((i) => currentPlayer.hand[i]).toList();
    final meld = Meld(cards: cards, type: type);

    if (!meld.isValid()) {
      message = 'Invalid meld!';
      return false;
    }

    // Check if this meld uses the required card from discard pile
    if (mustUseCard != null && cards.contains(mustUseCard)) {
      mustUseCard = null;
    }

    cardIndices.sort((a, b) => b.compareTo(a));
    for (final index in cardIndices) {
      currentPlayer.hand.removeAt(index);
    }

    currentPlayer.melds.add(meld);
    selectedHandIndices.clear();
    message = 'Meld played! You can play more melds or discard.';
    return true;
  }

  bool layoff(int handIndex, int meldPlayerIndex, int meldIndex) {
    if (currentPhase != GamePhase.play) return false;
    if (handIndex < 0 || handIndex >= currentPlayer.hand.length) return false;
    if (meldPlayerIndex < 0 || meldPlayerIndex >= players.length) return false;

    final targetPlayer = players[meldPlayerIndex];
    if (meldIndex < 0 || meldIndex >= targetPlayer.melds.length) return false;

    final card = currentPlayer.hand[handIndex];
    final meld = targetPlayer.melds[meldIndex];

    final testCards = List<PlayingCard>.from(meld.cards)..add(card);
    final testMeld = Meld(cards: testCards, type: meld.type);

    if (!testMeld.isValid()) {
      message = 'Cannot lay off this card!';
      return false;
    }

    // Check if laying off the required card from discard pile
    if (mustUseCard != null && card == mustUseCard) {
      mustUseCard = null;
    }

    meld.cards.add(card);
    currentPlayer.hand.removeAt(handIndex);
    message = 'Card laid off! You can play more or discard.';
    return true;
  }

  void discard(int handIndex) {
    if (currentPhase != GamePhase.play) return;
    if (handIndex < 0 || handIndex >= currentPlayer.hand.length) return;

    // Must use the drawn card from discard pile before discarding
    if (mustUseCard != null) {
      message = 'You must use ${mustUseCard!.rankSymbol}${mustUseCard!.suitSymbol} in a meld or lay it off first!';
      return;
    }

    final card = currentPlayer.hand.removeAt(handIndex);
    discardPile.add(card);

    if (currentPlayer.hand.isEmpty) {
      _endRound();
    } else {
      _nextTurn();
    }
  }

  void _nextTurn() {
    currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
    currentPhase = GamePhase.draw;
    drawnCard = null;
    mustUseCard = null;
    cardsDrawnFromDiscard.clear();
    selectedHandIndices.clear();
    message = '${currentPlayer.name}\'s turn';
  }

  void _endRound() {
    for (final player in players) {
      final roundScore = player.meldPoints - player.handPoints;
      player.score += roundScore;
    }

    if (isGameOver) {
      final winner = players.reduce((a, b) => a.score > b.score ? a : b);
      message = '${winner.name} wins with ${winner.score} points!';
    } else {
      message = 'Round over! Starting new round...';
      _startNewRound();
    }
  }

  void _startNewRound() {
    deck.reset();
    discardPile.clear();

    for (final player in players) {
      player.hand.clear();
      player.melds.clear();
    }

    currentPlayerIndex = 0;
    currentPhase = GamePhase.draw;
    drawnCard = null;
    mustUseCard = null;
    cardsDrawnFromDiscard.clear();
    selectedHandIndices.clear();

    dealCards();
  }

  RummyGameState copyWith({
    Deck? deck,
    List<PlayingCard>? discardPile,
    List<Player>? players,
    int? currentPlayerIndex,
    GamePhase? currentPhase,
    PlayingCard? drawnCard,
    int? selectedDiscardIndex,
    List<int>? selectedHandIndices,
    String? message,
    PlayingCard? mustUseCard,
    List<PlayingCard>? cardsDrawnFromDiscard,
  }) {
    return RummyGameState(
      deck: deck ?? this.deck,
      discardPile: discardPile ?? this.discardPile,
      players: players ?? this.players,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      currentPhase: currentPhase ?? this.currentPhase,
      drawnCard: drawnCard ?? this.drawnCard,
      selectedDiscardIndex: selectedDiscardIndex ?? this.selectedDiscardIndex,
      selectedHandIndices: selectedHandIndices ?? this.selectedHandIndices,
      message: message ?? this.message,
      mustUseCard: mustUseCard ?? this.mustUseCard,
      cardsDrawnFromDiscard: cardsDrawnFromDiscard ?? this.cardsDrawnFromDiscard,
    );
  }
}
