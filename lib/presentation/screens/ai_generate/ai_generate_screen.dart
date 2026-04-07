// lib/presentation/screens/ai_generate/ai_generate_screen.dart (STUB)
import 'package:flutter/material.dart';
import '../../../domain/entities/deck.dart';

class AIGenerateScreen extends StatelessWidget {
  final Deck deck;
  const AIGenerateScreen({super.key, required this.deck});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Gerar — ${deck.name}')),
    body: const Center(child: Text('AI Generate - coming soon')),
  );
}
