import 'dart:math';

import 'package:sabbac/game_logic/card.dart';

enum DrawCardType { sand, blood }

enum PlayerType { human, ai }

class Player {
  final PlayerType type;
  SabbacCard? bloodHand;
  SabbacCard? sandHand;

  SabbacCard? drawHand;
  DrawCardType? drawType;

  int coinBalance;
  int coinPile = 0;

  Player(this.type, {this.coinBalance = 6});

  bool get isHuman => type == PlayerType.human;
  bool get isAI => type == PlayerType.ai;
}

class SabbacGame {
  late List<Player> players;
  late List<SabbacCard> sandDeck;
  late List<SabbacCard> bloodDeck;

  List<SabbacCard> sandPile = [];
  List<SabbacCard> bloodPile = [];

  // Indicates the maximum number of rounds that can be played before we determine a winner of that round.
  final int roundLimit;

  // Indicates the number of rounds that have been played.
  int roundCount = 0;
  // Indicates the number turns that have been played, the game only ends until all players run out of coins.
  int turnCount = 0;

  List<Player> get aiPlayers => players.where((p) => p.isAI).toList();

  static const int maxCardsInHand = 2;
  int currentPlayerIndex = 0;

  // Each deck has maximum 1 sylop card and 3 imposter cards.
  // The rest of the deck is made up of numbered cards.
  SabbacGame(int playerCount, this.roundLimit) {
    if (playerCount < 2 || playerCount > 8) {
      throw ArgumentError('Player count must be between 2 and 8.');
    }

    players = List.generate(playerCount, (index) {
      if (index == 0) {
        return Player(PlayerType.human);
      } else {
        return Player(PlayerType.ai);
      }
    });

    sandDeck = populateDeck(true);
    bloodDeck = populateDeck(false);

    // Shuffle the decks.
    sandDeck.shuffle();
    bloodDeck.shuffle();
  }

  void play() {}

  // Each deck has maximum 1 sylop card and 3 imposter cards.
  // A deck consists of a total of 28 cards including the sylop and imposter cards.
  List<SabbacCard> populateDeck(bool isSand) {
    List<SabbacCard> deck = [];

    // Add 1 sylop card.
    deck.add(SabbacCard.sylop());

    // Add 3 imposter cards.
    for (int i = 0; i < 3; i++) {
      deck.add(SabbacCard.imposter());
    }

    // Add 24 numbered cards, each card must be between 1 and 6 and there may only be 4 cards of each value.
    for (int i = 1; i <= 6; i++) {
      for (int j = 0; j < 4; j++) {
        deck.add(SabbacCard.number(i));
      }
    }

    return deck;
  }

  void startRound() {
    roundCount++;
    turnCount = 0;

    // Deal two cards to each player.
    for (var player in players) {
      for (int i = 0; i < maxCardsInHand; i++) {
        drawStarterCard(player);
      }
    }

    // Clear the piles.
    sandPile.clear();
    bloodPile.clear();
  }

  void drawStarterCard(Player player) {
    player.sandHand = sandDeck.removeLast();
    player.bloodHand = bloodDeck.removeLast();
  }

  void drawCard(Player player, DrawCardType type, {bool coinCost = true}) {
    if (coinCost && player.coinBalance <= 0) {
      throw ArgumentError('Player has no coins.');
    }

    if (type == DrawCardType.sand) {
      player.drawHand = sandDeck.removeLast();
      player.drawType = DrawCardType.sand;
    } else {
      player.drawHand = bloodDeck.removeLast();
      player.drawType = DrawCardType.blood;
    }

    if (coinCost) {
      player.coinBalance--;
      player.coinPile++;
    }
  }

  void commitDraw(Player player) {
    if (player.drawHand == null || player.drawType == null) {
      throw ArgumentError('Player has not drawn a card.');
    }

    if (player.drawType == DrawCardType.sand) {
      if (player.sandHand != null) {
        sandPile.add(player.sandHand!);
      }

      player.sandHand = player.drawHand;
    } else {
      if (player.bloodHand != null) {
        bloodPile.add(player.bloodHand!);
      }

      player.bloodHand = player.drawHand;
    }

    player.drawHand = null;
    player.drawType = null;

    nextPlayer();
  }

  void discardDraw(Player player) {
    if (player.drawHand == null || player.drawType == null) {
      throw ArgumentError('Player has not drawn a card.');
    }

    if (player.drawType == DrawCardType.sand) {
      sandPile.add(player.drawHand!);
    } else {
      bloodPile.add(player.drawHand!);
    }

    player.drawHand = null;
    player.drawType = null;

    nextPlayer();
  }

  void nextPlayer() {
    currentPlayerIndex++;

    // If we've reached the end of the players list, we've completed a round.
    if (currentPlayerIndex >= players.length) {
      endRound();
      return;
    }

    // If next player is an AI, let the AI play.
    if (currentPlayer.isAI) {
      aiPlay(currentPlayer, currentPlayerIndex);
      return;
    }

    // If the current player is human, we wait for the user to make a move.
  }

  void endRound() {
    roundCount++;
    currentPlayerIndex = 0;

    // TODO: Calculate scores and determine winner.
    // TODO: Some players may have to roll the dice to determine their hand value.
  }

  // The objective for the AI is to get a sabbac.
  // The AI will always play the highest card in its hand.
  // If the AI has a sylop card, it will play it.
  // If the AI has an imposter card, it will play it.
  // In the case there's a better card on either the sand or blood pile, the AI will draw a card and replace the worst card in either of its hands.
  // If the AI has a sabbac, it will pass and wait for the next round.
  void aiPlay(Player player, int playerIndex) {
    final bloodHand = player.bloodHand;
    final sandHand = player.sandHand;

    print('AI Player $playerIndex is playing.');
    final hand = <SabbacCard?>[bloodHand, sandHand];
    final handIndex = hand.indexWhere((c) => c != null);
    final handType = handIndex == 0 ? DrawCardType.blood : DrawCardType.sand;

    // If the AI has a sabbac, it will pass.
    if (bloodHand!.value == 0 || sandHand!.value == 0) {
      print('I have a sabbac, I pass.');
      return;
    }

    nextPlayer();
  }

  void drawCardFromPile(Player player, DrawCardType type) {
    if (type == DrawCardType.sand) {
      if (player.sandHand != null) {
        sandPile.add(player.sandHand!);
      }

      player.sandHand = sandPile.removeLast();
    } else {
      if (player.bloodHand != null) {
        bloodPile.add(player.bloodHand!);
      }

      player.bloodHand = bloodPile.removeLast();
    }
  }

  int rollDice() {
    Random random = Random();
    return random.nextInt(6) + 1;
  }

  // If this returns -1, the hand is not yet decided for since it contains an imposter card.
  // If this returns 0, it means we have a sabacc.
  int calculateHandValue(Player player, {bool decisive = false}) {
    List<SabbacCard> hand = [
      player.bloodHand ?? SabbacCard.sylop(),
      player.sandHand ?? SabbacCard.sylop(),
    ];

    int sandHand = hand[0].value;
    int bloodHand = hand[1].value;

    if (hand[0].type == CardType.sylop) {
      sandHand = hand[1].type == CardType.sylop ? bloodHand : hand[1].value;
    } else if (hand[0].type == CardType.imposter) {
      if (decisive) {
        sandHand = rollDice();
      } else {
        return -1;
      }
    }

    if (hand[1].type == CardType.sylop) {
      bloodHand = hand[0].type == CardType.sylop ? sandHand : hand[0].value;
    } else if (hand[1].type == CardType.imposter) {
      if (decisive) {
        bloodHand = rollDice();
      } else {
        return -1;
      }
    }

    // Check for Pure Sabacc
    if (hand[0].type == CardType.sylop && hand[1].type == CardType.sylop) {
      return 0; // Pure Sabacc
    }

    return (sandHand - bloodHand).abs();
  }

  // Check if the hand is a sabbac. (Two cards of equal value)
  bool isSabbac(Player player) {
    return calculateHandValue(player) == 0;
  }

  // Since equal cards result in sabbac, the rank is determined by the lower card. Lower card is better.
  int sabbacRank(Player player) {
    if (!isSabbac(player)) {
      throw ArgumentError('Hand is not a sabbac.');
    }
    return player.bloodHand!.value;
  }

  Player get currentPlayer => players[currentPlayerIndex];
  Player get humanPlayer => players.firstWhere((p) => p.isHuman);
}
