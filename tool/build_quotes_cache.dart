import 'dart:io';

import 'package:wisely/src/domain/curation/quote_curation.dart';

Future<void> main() async {
  final root = Directory.current;
  final rawFile = File(
    '${root.path}${Platform.pathSeparator}silvator${Platform.pathSeparator}quotes.json',
  );
  final curatedFile = File(
    '${root.path}${Platform.pathSeparator}assets${Platform.pathSeparator}data${Platform.pathSeparator}quotes_curated.json',
  );
  final versionFile = File(
    '${root.path}${Platform.pathSeparator}assets${Platform.pathSeparator}data${Platform.pathSeparator}catalog_version.json',
  );

  if (!rawFile.existsSync()) {
    stderr.writeln('Missing input file: ${rawFile.path}');
    exitCode = 1;
    return;
  }

  final rawContent = await rawFile.readAsString();
  final rawQuotes = parseRawQuotes(rawContent);
  final curatedCatalog = curateQuotes(rawQuotes);

  await curatedFile.parent.create(recursive: true);
  await curatedFile.writeAsString(encodeCuratedQuotes(curatedCatalog.quotes));
  await versionFile.writeAsString(encodeCatalogVersion(curatedCatalog.version));

  stdout.writeln(
    'Curated ${curatedCatalog.quotes.length} quotes. Version ${curatedCatalog.version.version}.',
  );
  for (final entry in curatedCatalog.version.moodCounts.entries) {
    stdout.writeln('  ${entry.key.name}: ${entry.value}');
  }
}
