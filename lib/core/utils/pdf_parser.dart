import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

enum PdfParseMode {
  /// IA identifica pares bilíngues no texto (inglês/português)
  lineByLine,
  /// IA interpreta o texto livremente (texto bruto enviado para OpenAI)
  aiInterpreted,
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

  /// Extrai texto de um PPTX (ZIP com XMLs de slides)
  static String extractTextFromPptx(Uint8List pptxBytes) {
    final archive = ZipDecoder().decodeBytes(pptxBytes);
    final buffer = StringBuffer();

    // Slides are in ppt/slides/slide1.xml, slide2.xml, etc.
    final slideFiles = archive.files
        .where((f) =>
            f.name.startsWith('ppt/slides/slide') && f.name.endsWith('.xml'))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    for (final file in slideFiles) {
      final content = String.fromCharCodes(file.content as List<int>);
      // Extract text between <a:t> tags (PowerPoint text runs)
      final matches = RegExp(r'<a:t>([^<]+)</a:t>').allMatches(content);
      for (final match in matches) {
        final text = match.group(1)?.trim() ?? '';
        if (text.isNotEmpty) {
          buffer.writeln(text);
        }
      }
      buffer.writeln(); // blank line between slides
    }

    return buffer.toString();
  }

  /// Modo lineByLine: limpa ruído e retorna texto para a IA extrair pares
  /// A IA é quem identifica os pares bilíngues no texto
  static String prepareLineByLineForAI(String rawText) {
    final lines = rawText.split('\n').map((l) => l.trim()).toList();

    // Filter out noise: copyright lines, base64 strings, page numbers, empty
    final cleaned = lines.where((l) {
      if (l.isEmpty) return false;
      if (l.length < 3) return false;
      // Base64-encoded strings
      if (RegExp(r'^[A-Za-z0-9+/=]{20,}$').hasMatch(l)) return false;
      // Copyright / watermark lines
      if (l.contains('©') || l.contains('CIMV')) return false;
      // Pure page numbers
      if (RegExp(r'^\d{1,3}$').hasMatch(l)) return false;
      return true;
    }).toList();

    return cleaned.join('\n');
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
