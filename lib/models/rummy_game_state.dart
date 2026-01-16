import 'playing_card.dart';

enum MeldType { set, run }

class Meld {
  Meld({required this.cards, required this.type});
  final List<PlayingCard> cards;
  final MeldType type;

  int get points {
    return cards.fold(0, (sum, card) => sum + card.points);
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
      if (!card.isJoker && card.rank != rank) return false;
      if (!card.isJoker) suits.add(card.suit);
    }

    return suits.length == cards.where((c) => !c.isJoker).length;
  }

  bool _isValidRun() {
    if (cards.isEmpty) return false;

    final suit = cards
        .firstWhere((c) => !c.isJoker, orElse: () => cards.first)
        .suit;
    final nonJokers = cards.where((c) => !c.isJoker).toList();

    for (final card in nonJokers) {
      if (card.suit != suit) return false;
    }

    final sortedCards = List<PlayingCard>.from(cards);
    sortedCards.sort((a, b) => a.rank.index.compareTo(b.rank.index));

    int expectedIndex = sortedCards.first.rank.index;
    for (var i = 0; i < sortedCards.length; i++) {
      if (!sortedCards[i].isJoker) {
        if (sortedCards[i].rank.index != expectedIndex) return false;
      }
      expectedIndex++;
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
    return hand.fold(0, (sum, card) => sum + card.points);
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
  }) : selectedHandIndices = selectedHandIndices ?? [];
  final Deck deck;
  final List<PlayingCard> discardPile;
  final List<Player> players;
  int currentPlayerIndex;
  GamePhase currentPhase;
  PlayingCard? drawnCard;
  int? selectedDiscardIndex;
  List<int> selectedHandIndices;
  String? message;

  Player get currentPlayer => players[currentPlayerIndex];

  bool get isGameOver => players.any((p) => p.score >= 500);

  void dealCards() {
    for (var i = 0; i < 13; i++) {
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

    for (var i = discardPile.length - 1; i >= discardIndex; i--) {
      currentPlayer.hand.add(discardPile[i]);
    }

    discardPile.removeRange(discardIndex, discardPile.length);
    currentPlayer.sortHand();
    currentPhase = GamePhase.play;
    message = 'Drew cards from discard pile. Play melds or discard.';
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

    meld.cards.add(card);
    currentPlayer.hand.removeAt(handIndex);
    message = 'Card laid off! You can play more or discard.';
    return true;
  }

  void discard(int handIndex) {
    if (currentPhase != GamePhase.play) return;
    if (handIndex < 0 || handIndex >= currentPlayer.hand.length) return;

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
    );
  }
}
