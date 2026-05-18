import 'package:flutter/material.dart';
import 'package:wisely/src/domain/entities/mood_type.dart';
import 'package:wisely/src/presentation/branding/silvator_mascot.dart';
import 'package:wisely/src/presentation/theme/wisely_theme.dart';

class SilvatorMascotAvatar extends StatelessWidget {
  const SilvatorMascotAvatar({
    super.key,
    required this.mood,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.borderRadius,
    this.semanticLabel,
  });

  final MoodType mood;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final profile = silvatorMascotProfileFor(mood);
    final image = Image.asset(
      profile.assetPath,
      key: Key('silvator-mascot-${mood.name}'),
      width: width,
      height: height,
      fit: fit,
      semanticLabel: semanticLabel ?? '${mood.label} mascot',
      errorBuilder: (_, _, _) {
        return SizedBox(
          width: width,
          height: height,
          child: Center(
            child: Text(
              moodGlyphs[mood]!,
              style: TextStyle(fontSize: _fallbackFontSize),
            ),
          ),
        );
      },
    );

    if (borderRadius == null) {
      return image;
    }

    return ClipRRect(borderRadius: borderRadius!, child: image);
  }

  double get _fallbackFontSize {
    final shortestSide = [?width, ?height].fold<double?>(null, (
      current,
      value,
    ) {
      if (current == null || value < current) {
        return value;
      }
      return current;
    });
    if (shortestSide == null) {
      return 18;
    }
    return (shortestSide * 0.42).clamp(12, 34).toDouble();
  }
}
