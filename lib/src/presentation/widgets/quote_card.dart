import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wisely/src/domain/entities/mood_type.dart';
import 'package:wisely/src/domain/entities/quote_entry.dart';
import 'package:wisely/src/presentation/theme/wisely_theme.dart';
import 'package:wisely/src/presentation/widgets/silvator_mascot_avatar.dart';

class QuoteCard extends StatelessWidget {
  const QuoteCard({
    super.key,
    required this.quote,
    required this.mood,
    required this.isLiked,
    required this.onLike,
    required this.onCopy,
    required this.onShare,
    required this.onShowDetails,
    this.onSendToWidget,
    this.onRefresh,
    this.title,
    this.subtitle,
    this.compact = false,
  });

  final QuoteEntry quote;
  final MoodType mood;
  final bool isLiked;
  final VoidCallback onLike;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onShowDetails;
  final VoidCallback? onSendToWidget;
  final VoidCallback? onRefresh;
  final String? title;
  final String? subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = moodColors[mood]!;
    final dark = context.isDarkMode;
    final motionDisabled = MediaQuery.disableAnimationsOf(context);
    final effectiveCompact = compact || MediaQuery.sizeOf(context).width < 420;

    final card = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(effectiveCompact ? 26 : 34),
        gradient: LinearGradient(
          colors: [
            context.glassSurfaceHigh(lightAlpha: 0.88, darkAlpha: 0.92),
            accent.withValues(alpha: dark ? 0.18 : 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: context.surfaceStroke()),
        boxShadow: [
          BoxShadow(
            color: dark
                ? Colors.black.withValues(alpha: 0.26)
                : accent.withValues(alpha: 0.14),
            blurRadius: dark ? 34 : 46,
            offset: Offset(0, dark ? 12 : 18),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(effectiveCompact ? 26 : 34),
          onTap: onShowDetails,
          child: Padding(
            padding: EdgeInsets.all(effectiveCompact ? 18 : 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: context.accentSurface(
                            accent,
                            lightAlpha: 0.22,
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SilvatorMascotAvatar(
                              mood: mood,
                              width: 24,
                              height: 24,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                title ?? mood.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: dark
                                      ? const Color(0xFFE8EBF1)
                                      : const Color(0xFF43464C),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: onLike,
                      style: IconButton.styleFrom(
                        backgroundColor: context.glassSurface(
                          lightAlpha: 0.62,
                          darkAlpha: 0.84,
                        ),
                      ),
                      icon: AnimatedSwitcher(
                        duration: motionDisabled
                            ? Duration.zero
                            : const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOutBack,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                        child: Icon(
                          isLiked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          key: ValueKey<bool>(isLiked),
                          color: isLiked
                              ? const Color(0xFFDA5677)
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Text(
                  '"${quote.text}"',
                  style: GoogleFonts.lora(
                    textStyle: effectiveCompact
                        ? theme.textTheme.headlineSmall
                        : theme.textTheme.headlineMedium,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.accentSurface(accent),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        moodIcons[mood],
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        quote.author,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: dark
                            ? const Color(0xFFE8C877)
                            : const Color(0xFF9C6908),
                        foregroundColor: dark
                            ? const Color(0xFF1B1A14)
                            : Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      onPressed: onShowDetails,
                      child: const Text('Rest in this moment'),
                    ),
                    OutlinedButton.icon(
                      onPressed: onCopy,
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Copy'),
                    ),
                    if (onRefresh != null)
                      OutlinedButton.icon(
                        onPressed: onRefresh,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('New quote'),
                      ),
                    OutlinedButton.icon(
                      onPressed: onShare,
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('Share'),
                    ),
                    if (onSendToWidget != null)
                      Tooltip(
                        message: 'Update Android home widget',
                        child: OutlinedButton.icon(
                          onPressed: onSendToWidget,
                          icon: const Icon(Icons.widgets_rounded),
                          label: const Text('Update widget'),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (motionDisabled) {
      return card;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 14),
            child: Transform.scale(
              scale: 0.98 + (value * 0.02),
              alignment: Alignment.topCenter,
              child: child,
            ),
          ),
        );
      },
      child: card,
    );
  }
}
