import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wisely/src/application/ports/platform_ports.dart';
import 'package:wisely/src/domain/entities/quote_entry.dart';

class SystemQuoteActions implements QuoteActionsPort {
  @override
  Future<void> copyQuote(QuoteEntry quote) async {
    await Clipboard.setData(
      ClipboardData(text: '${quote.text}\n\n${quote.author}'),
    );
  }

  @override
  Future<void> shareQuote(QuoteEntry quote) async {
    await SharePlus.instance.share(
      ShareParams(
        text: '"${quote.text}"\n\n${quote.author}',
        title: 'Share quote from Selvator',
      ),
    );
  }
}
