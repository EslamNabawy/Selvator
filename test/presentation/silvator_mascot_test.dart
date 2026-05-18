import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wisely/src/domain/entities/mood_type.dart';
import 'package:wisely/src/presentation/branding/silvator_mascot.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('runtime silvator asset filenames are normalized', () {
    final files = Directory('assets/images/silvator')
        .listSync()
        .whereType<File>()
        .map((file) => file.uri.pathSegments.last)
        .toSet();

    expect(files, {
      'angry.webp',
      'anxiety.webp',
      'bored.webp',
      'confidence.webp',
      'fear.webp',
      'happy.webp',
      'lonely.webp',
      'love.webp',
      'original.webp',
      'sad.webp',
      'stress.webp',
    });
    expect(files.any((name) => RegExp(r'[A-Z]').hasMatch(name)), isFalse);
  });

  test(
    'every app mood has a silvator mascot profile with existing asset',
    () async {
      for (final mood in MoodType.values) {
        final profile = silvatorMascotProfileFor(mood);

        expect(profile.mood, mood);
        expect(profile.name, isNotEmpty);
        expect(profile.symbol, isNotEmpty);
        expect(profile.description, isNotEmpty);
        expect(profile.assetPath, startsWith('assets/images/silvator/'));
        expect(File(profile.assetPath).existsSync(), isTrue);
        expect(await rootBundle.load(profile.assetPath), isA<ByteData>());
      }
    },
  );
}
