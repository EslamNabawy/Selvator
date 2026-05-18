import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('source follows clean architecture layer boundaries', () {
    final libRoot = Directory('lib/src');
    final files = libRoot
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .toList(growable: false);

    expect(Directory('lib/src/domain').existsSync(), isTrue);
    expect(Directory('lib/src/application').existsSync(), isTrue);
    expect(Directory('lib/src/data').existsSync(), isTrue);
    expect(Directory('lib/src/infrastructure').existsSync(), isTrue);
    expect(Directory('lib/src/presentation').existsSync(), isTrue);

    expect(Directory('lib/src/core').existsSync(), isFalse);
    expect(Directory('lib/src/services').existsSync(), isFalse);
    expect(Directory('lib/src/state').existsSync(), isFalse);
    expect(Directory('lib/src/ui').existsSync(), isFalse);
    expect(Directory('lib/src/theme').existsSync(), isFalse);

    final violations = <String>[];
    for (final file in files) {
      final normalizedPath = file.path.replaceAll('\\', '/');
      final source = file.readAsStringSync();

      void forbid(String importPrefix) {
        if (source.contains("package:wisely/src/$importPrefix")) {
          violations.add('$normalizedPath imports $importPrefix');
        }
      }

      if (normalizedPath.startsWith('lib/src/domain/')) {
        for (final forbidden in [
          'application/',
          'data/',
          'infrastructure/',
          'presentation/',
        ]) {
          forbid(forbidden);
        }
        if (source.contains("package:flutter/") ||
            source.contains("package:flutter_riverpod/")) {
          violations.add('$normalizedPath imports Flutter/Riverpod');
        }
      }

      if (normalizedPath.startsWith('lib/src/application/')) {
        for (final forbidden in ['data/', 'infrastructure/', 'presentation/']) {
          forbid(forbidden);
        }
      }

      if (normalizedPath.startsWith('lib/src/presentation/')) {
        for (final forbidden in ['data/', 'infrastructure/']) {
          forbid(forbidden);
        }
      }
    }

    expect(violations, isEmpty);
  });
}
