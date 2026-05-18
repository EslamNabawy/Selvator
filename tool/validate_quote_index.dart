import 'dart:convert';
import 'dart:io';

import 'package:wisely/src/domain/entities/quote_entry.dart';
import 'package:wisely/src/domain/curation/quote_curation.dart';

Future<void> main() async {
  final root = Directory.current;
  final curatedFile = File(
    '${root.path}${Platform.pathSeparator}assets${Platform.pathSeparator}data${Platform.pathSeparator}quotes_curated.json',
  );

  if (!curatedFile.existsSync()) {
    stderr.writeln('Missing curated catalog: ${curatedFile.path}');
    stderr.writeln('Run `dart run tool/build_quotes_cache.dart` first.');
    exitCode = 1;
    return;
  }

  final decoded = jsonDecode(await curatedFile.readAsString()) as List<dynamic>;
  final quotes = decoded
      .map((item) => QuoteEntry.fromJson(item as Map<String, dynamic>))
      .toList(growable: false);
  final result = validateCatalog(quotes);

  stdout.writeln('Mood coverage:');
  for (final entry in result.coverage.entries) {
    stdout.writeln(
      '  ${entry.key.name}: core=${entry.value.core}  '
      'extended=${entry.value.extended}  '
      'cold-eligible=${entry.value.coldEligible}',
    );
  }

  stdout.writeln('\nAuthor distribution (top 10 per mood):');
  for (final entry in result.authorDistribution.entries) {
    final authors = entry.value.entries
        .map((author) => '${author.key} x${author.value}')
        .join(', ');
    stdout.writeln('  ${entry.key.name}: $authors');
  }

  stdout.writeln('\nPotential issues:');
  if (result.issues.isEmpty) {
    stdout.writeln('  [ok] no issues detected');
  } else {
    for (final issue in result.issues) {
      stdout.writeln('  [!] $issue');
    }
  }
}
