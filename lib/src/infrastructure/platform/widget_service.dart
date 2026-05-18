import 'dart:convert';
import 'dart:io';

import 'package:home_widget/home_widget.dart';
import 'package:wisely/src/application/ports/platform_ports.dart';
import 'package:wisely/src/domain/entities/mood_type.dart';
import 'package:wisely/src/domain/entities/quote_entry.dart';
import 'package:wisely/src/infrastructure/platform/models/widget_quote_payload.dart';

class WidgetService implements QuoteWidgetPort {
  static const widgetDataKey = 'widget_payload';
  static const widgetProviderName = 'WiselyQuoteWidgetProvider';
  static const qualifiedAndroidName =
      'com.eslam.wisely.wisely.WiselyQuoteWidgetProvider';

  @override
  bool get isSupported => Platform.isAndroid;

  @override
  Future<void> syncQuote({
    required QuoteEntry quote,
    required MoodType mood,
  }) async {
    if (!isSupported) {
      return;
    }

    final payload = WidgetQuotePayload(
      quoteId: quote.id,
      mood: mood,
      text: quote.text,
      author: quote.author,
      accentKey: mood.accentKey,
      updatedAt: DateTime.now(),
    );
    await HomeWidget.saveWidgetData<String>(
      widgetDataKey,
      jsonEncode(payload.toJson()),
    );
    await HomeWidget.updateWidget(
      name: widgetProviderName,
      qualifiedAndroidName: qualifiedAndroidName,
    );
  }
}
