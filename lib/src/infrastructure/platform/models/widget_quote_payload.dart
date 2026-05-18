import 'package:wisely/src/domain/entities/mood_type.dart';

class WidgetQuotePayload {
  const WidgetQuotePayload({
    required this.quoteId,
    required this.mood,
    required this.text,
    required this.author,
    required this.accentKey,
    required this.updatedAt,
  });

  final String quoteId;
  final MoodType mood;
  final String text;
  final String author;
  final String accentKey;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'quoteId': quoteId,
      'mood': mood.name,
      'text': text,
      'author': author,
      'accentKey': accentKey,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory WidgetQuotePayload.fromJson(Map<String, dynamic> json) {
    return WidgetQuotePayload(
      quoteId: json['quoteId'].toString(),
      mood: MoodType.fromKey(json['mood'].toString()),
      text: json['text'].toString(),
      author: json['author'].toString(),
      accentKey: json['accentKey'].toString(),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
