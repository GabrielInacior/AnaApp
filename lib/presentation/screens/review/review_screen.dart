// lib/presentation/screens/review/review_screen.dart
import 'package:flutter/material.dart';

class ReviewScreen extends StatelessWidget {
  final String deckId;
  final String deckName;
  const ReviewScreen({super.key, required this.deckId, required this.deckName});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(deckName)),
    body: const Center(child: Text('Review - coming soon')),
  );
}
