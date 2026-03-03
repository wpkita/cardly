enum Suit { hearts, diamonds, clubs, spades }

enum Rank {
  ace,
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  nine,
  ten,
  jack,
  queen,
  king,
}

class PlayingCard {
  PlayingCard({required this.suit, required this.rank});
  final Suit suit;
  final Rank rank;

  String get suitSymbol {
    switch (suit) {
      case Suit.hearts:
        return '♥';
      case Suit.diamonds:
        return '♦';
      case Suit.clubs:
        return '♣';
      case Suit.spades:
        return '♠';
    }
  }

  String get rankSymbol {
    switch (rank) {
      case Rank.ace:
        return 'A';
      case Rank.two:
        return '2';
      case Rank.three:
        return '3';
      case Rank.four:
        return '4';
      case Rank.five:
        return '5';
      case Rank.six:
        return '6';
      case Rank.seven:
        return '7';
      case Rank.eight:
        return '8';
      case Rank.nine:
        return '9';
      case Rank.ten:
        return '10';
      case Rank.jack:
        return 'J';
      case Rank.queen:
        return 'Q';
      case Rank.king:
        return 'K';
    }
  }

  bool get isRed => suit == Suit.hearts || suit == Suit.diamonds;

  /// Returns the point value of this card.
  /// For Ace, pass [aceHigh] = false to get 1 point (when used in A-2-3),
  /// or true (default) to get 15 points (when used in Q-K-A or in a set).
  int points({bool aceHigh = true}) {
    switch (rank) {
      case Rank.ace:
        return aceHigh ? 15 : 1;
      case Rank.two:
        return 2;
      case Rank.three:
        return 3;
      case Rank.four:
        return 4;
      case Rank.five:
        return 5;
      case Rank.six:
        return 6;
      case Rank.seven:
        return 7;
      case Rank.eight:
        return 8;
      case Rank.nine:
        return 9;
      case Rank.ten:
      case Rank.jack:
      case Rank.queen:
      case Rank.king:
        return 10;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayingCard &&
          runtimeType == other.runtimeType &&
          suit == other.suit &&
          rank == other.rank;

  @override
  int get hashCode => suit.hashCode ^ rank.hashCode;

  @override
  String toString() => '$rankSymbol$suitSymbol';
}

class Deck {
  Deck() {
    _initialize();
  }
  final List<PlayingCard> cards = [];

  void _initialize() {
    cards.clear();

    // Standard 52-card pack
    for (final suit in Suit.values) {
      for (final rank in Rank.values) {
        cards.add(PlayingCard(suit: suit, rank: rank));
      }
    }
  }

  void shuffle() {
    cards.shuffle();
  }

  PlayingCard? draw() {
    if (cards.isEmpty) return null;
    return cards.removeLast();
  }

  void reset() {
    _initialize();
    shuffle();
  }

  int get count => cards.length;
}
