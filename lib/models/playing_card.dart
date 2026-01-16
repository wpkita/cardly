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
  PlayingCard({required this.suit, required this.rank, this.isJoker = false});
  final Suit suit;
  final Rank rank;
  final bool isJoker;

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

  int get points {
    if (isJoker) return 15;
    switch (rank) {
      case Rank.ace:
        return 15;
      case Rank.two:
      case Rank.three:
      case Rank.four:
      case Rank.five:
      case Rank.six:
      case Rank.seven:
      case Rank.eight:
      case Rank.nine:
        return 5;
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
          rank == other.rank &&
          isJoker == other.isJoker;

  @override
  int get hashCode => suit.hashCode ^ rank.hashCode ^ isJoker.hashCode;

  @override
  String toString() => isJoker ? 'Joker' : '$rankSymbol$suitSymbol';
}

class Deck {
  Deck() {
    _initialize();
  }
  final List<PlayingCard> cards = [];

  void _initialize() {
    cards.clear();

    for (final suit in Suit.values) {
      for (final rank in Rank.values) {
        cards.add(PlayingCard(suit: suit, rank: rank));
        cards.add(PlayingCard(suit: suit, rank: rank));
      }
    }

    cards.add(PlayingCard(suit: Suit.hearts, rank: Rank.ace, isJoker: true));
    cards.add(PlayingCard(suit: Suit.spades, rank: Rank.ace, isJoker: true));
    cards.add(PlayingCard(suit: Suit.diamonds, rank: Rank.ace, isJoker: true));
    cards.add(PlayingCard(suit: Suit.clubs, rank: Rank.ace, isJoker: true));
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
