// lib/presentation/screens/decks/deck_detail_screen.dart (STUB)
import 'package:flutter/material.dart';
import '../../../domain/entities/deck.dart';

class DeckDetailScreen extends StatelessWidget {
  final Deck deck;
  const DeckDetailScreen({super.key, required this.deck});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(deck.name)),
    body: const Center(child: Text('Deck Detail - coming soon')),
  );
}
