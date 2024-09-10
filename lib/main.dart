// main.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sabbac/game_logic/card.dart';
import 'package:sabbac/game_logic/sabbac.dart';
import 'package:yaru/yaru.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sabbac Game',
      theme: yaruLight,
      darkTheme: yaruDark,
      debugShowCheckedModeBanner: false,
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  GameScreenState createState() => GameScreenState();
}

class GameScreenState extends State<GameScreen> {
  late SabbacGame game;

  @override
  void initState() {
    super.initState();

    game = SabbacGame(4, 3);
    game.startRound();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sabbac'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Current player index:
            Text('Current Player: ${game.currentPlayerIndex}'),

            buildGameBanner(),
            buildAICards(),
            buildPiles(),
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Text(
                    'You',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      buildPlayerCard(),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          Text('Coins: ${game.humanPlayer.coinBalance}'),
                          Text('Coin Pile: ${game.humanPlayer.coinPile}'),
                        ],
                      ),
                      buildActionButtons(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build pile, only display the top card of each pile.
  Widget buildPiles() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          children: [
            Text(
              'Sand Pile',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            CardWidget(
              game.sandPile.isNotEmpty ? game.sandPile.last : null,
              DrawCardType.sand,
            ),
          ],
        ),
        Column(
          children: [
            Text(
              'Sand Deck',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            CardWidget(
              game.sandDeck.isNotEmpty ? game.sandDeck.last : null,
              hidden: true,
              DrawCardType.sand,
            ),
            const SizedBox(height: 4),
            IconButton.outlined(
              onPressed: (game.humanPlayer.drawHand != null ||
                      !game.currentPlayer.isHuman)
                  ? null
                  : () {
                      game.drawCard(game.humanPlayer, DrawCardType.sand);
                      setState(() {});
                    },
              icon: const Icon(
                FontAwesomeIcons.layerGroup,
                size: 12,
              ),
            ),
          ],
        ),
        Column(
          children: [
            Text(
              'Blood Deck',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            CardWidget(
              game.bloodDeck.isNotEmpty ? game.bloodDeck.last : null,
              hidden: true,
              DrawCardType.blood,
            ),
            const SizedBox(height: 4),
            IconButton.outlined(
              onPressed: (game.humanPlayer.drawHand != null ||
                      !game.currentPlayer.isHuman)
                  ? null
                  : () {
                      game.drawCard(game.humanPlayer, DrawCardType.blood);
                      setState(() {});
                    },
              icon: const Icon(
                FontAwesomeIcons.layerGroup,
                size: 12,
              ),
            ),
          ],
        ),
        Column(
          children: [
            Text(
              'Blood Pile',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            CardWidget(
              game.bloodPile.isNotEmpty ? game.bloodPile.last : null,
              DrawCardType.blood,
            ),
          ],
        ),
      ],
    );
  }

  // Game banner displays the current round and turn count and limits.
  Widget buildGameBanner() {
    return Column(
      children: [
        Text(
          'Games: ${game.turnCount + 1}',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Text(
          'Round: ${game.roundCount} / ${game.roundLimit}',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ],
    );
  }

  Widget buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          if (game.humanPlayer.drawHand == null && game.currentPlayer.isHuman)
            OutlinedButton(
              onPressed: () {
                game.nextPlayer();
                setState(() {});
              },
              child: const Text('Pass Turn'),
            ),

          const SizedBox(width: 8),

          // In case we have a draw hand, we can commit the draw or cancel it.
          if (game.humanPlayer.drawHand != null) ...[
            // Show the drawn card so the use can decide to commit or discard it.
            CardWidget(
              game.humanPlayer.drawHand,
              game.humanPlayer.drawType!,
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(
                  onPressed: () {
                    game.commitDraw(game.humanPlayer);
                    setState(() {});
                  },
                  child: const Text('Commit Draw'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    game.discardDraw(game.humanPlayer);
                    setState(() {});
                  },
                  child: const Text('Discard Draw'),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget buildPlayerCard() {
    return Column(
      children: [
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: [
            CardWidget(game.humanPlayer.sandHand ?? SabbacCard.sylop(),
                DrawCardType.sand),
            CardWidget(game.humanPlayer.bloodHand ?? SabbacCard.sylop(),
                DrawCardType.blood),
          ],
        ),
        Text('${game.calculateHandValue(game.humanPlayer)}'),
      ],
    );
  }

  Widget buildAICards() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: game.aiPlayers
          .map(
            (player) => Column(
              children: [
                Text(
                  'AI Player ${game.players.indexOf(player)}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                    'Coins: ${player.coinBalance} - Coin Pile: ${player.coinPile}'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: [
                    CardWidget(player.sandHand, DrawCardType.sand,
                        hidden: true),
                    CardWidget(player.bloodHand, DrawCardType.blood,
                        hidden: true),
                  ],
                ),
                Text('${game.calculateHandValue(player)}'),
              ],
            ),
          )
          .toList(),
    );
  }
}

class CardWidget extends StatelessWidget {
  final SabbacCard? card;
  final DrawCardType drawType;
  final bool hidden;

  const CardWidget(this.card, this.drawType, {super.key, this.hidden = false});

  // A card is a elongated hexagon with a border and a number or text in the middle.
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 70,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).cardColor,
      ),
      child: hidden
          ? const Text('H')
          : card != null
              ? Text(
                  card!.type == CardType.number
                      ? card!.value.toString()
                      : card!.toString(),
                  style: Theme.of(context).textTheme.headlineMedium,
                )
              : const SizedBox(),
    );
  }
}
