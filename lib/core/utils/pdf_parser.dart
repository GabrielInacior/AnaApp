import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';

enum PdfParseMode {
  /// Linha ímpar = inglês, linha par = português
  lineByLine,
  /// IA interpreta o texto livremente (texto bruto enviado para OpenAI)
  aiInterpreted,
}

class ParsedCardPair {
  final String front;
  final String back;
  const ParsedCardPair({required this.front, required this.back});
}

class PdfParser {
  PdfParser._();

  /// Extrai texto bruto do PDF
  static String extractRawText(Uint8List pdfBytes) {
    final document = PdfDocument(inputBytes: pdfBytes);
    final extractor = PdfTextExtractor(document);
    final text = extractor.extractText();
    document.dispose();
    return text;
  }

  /// Modo lineByLine: cada par de linhas consecutivas forma um card
  static List<ParsedCardPair> parseLineByLine(String rawText) {
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final pairs = <ParsedCardPair>[];
    for (int i = 0; i + 1 < lines.length; i += 2) {
      pairs.add(ParsedCardPair(front: lines[i], back: lines[i + 1]));
    }
    return pairs;
  }

  /// Modo aiInterpreted: retorna o texto bruto para a IA processar
  static String prepareTextForAI(String rawText) {
    return rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .join('\n');
  }
}
