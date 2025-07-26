/// Extracted word from OCR processing - matches backend ExtractedWord model
class ExtractedWord {
  final String word;
  final String translation;
  final double confidence;
  bool isSelected; // For UI selection

  ExtractedWord({
    required this.word,
    required this.translation,
    required this.confidence,
    this.isSelected = false,
  });

  factory ExtractedWord.fromJson(Map<String, dynamic> json) {
    return ExtractedWord(
      word: json['word'],
      translation: json['translation'],
      confidence: (json['confidence'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'translation': translation,
      'confidence': confidence,
    };
  }

  @override
  String toString() {
    return 'ExtractedWord{word: $word, translation: $translation, confidence: $confidence}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ExtractedWord &&
              runtimeType == other.runtimeType &&
              word == other.word;

  @override
  int get hashCode => word.hashCode;
}

/// OCR Response from backend - matches backend OCRResponse model
class OCRResponse {
  final List<ExtractedWord> extractedWords;
  final int totalExtracted;
  final double processingTime;

  OCRResponse({
    required this.extractedWords,
    required this.totalExtracted,
    required this.processingTime,
  });

  factory OCRResponse.fromJson(Map<String, dynamic> json) {
    return OCRResponse(
      extractedWords: (json['extracted_words'] as List<dynamic>)
          .map((word) => ExtractedWord.fromJson(word as Map<String, dynamic>))
          .toList(),
      totalExtracted: json['total_extracted'],
      processingTime: (json['processing_time'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'extracted_words': extractedWords.map((word) => word.toJson()).toList(),
      'total_extracted': totalExtracted,
      'processing_time': processingTime,
    };
  }

  @override
  String toString() {
    return 'OCRResponse{extractedWords: ${extractedWords.length}, totalExtracted: $totalExtracted, processingTime: $processingTime}';
  }
}

/// Request model for bulk adding words - matches backend BulkAddRequest
class BulkAddWordRequest {
  final String word;
  final String translation;
  final String? exampleSentence;

  BulkAddWordRequest({
    required this.word,
    required this.translation,
    this.exampleSentence,
  });

  factory BulkAddWordRequest.fromExtractedWord(ExtractedWord extractedWord) {
    return BulkAddWordRequest(
      word: extractedWord.word,
      translation: extractedWord.translation,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'translation': translation,
      'example_sentence': exampleSentence,
    };
  }

  @override
  String toString() {
    return 'BulkAddWordRequest{word: $word, translation: $translation}';
  }
}