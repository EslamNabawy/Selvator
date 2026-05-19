import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:wisely/src/domain/entities/mood_type.dart';
import 'package:wisely/src/presentation/theme/wisely_theme.dart';
import 'package:wisely/src/presentation/widgets/silvator_mascot_avatar.dart';

class MoodChipRow extends StatefulWidget {
  const MoodChipRow({
    super.key,
    required this.selectedMood,
    required this.onMoodSelected,
    this.selectedMoods = const [],
    this.maxSelectedMoods = 3,
  });

  final MoodType selectedMood;
  final List<MoodType> selectedMoods;
  final ValueChanged<MoodType> onMoodSelected;
  final int maxSelectedMoods;

  @override
  State<MoodChipRow> createState() => _MoodChipRowState();
}

class _MoodChipRowState extends State<MoodChipRow> {
  final ScrollController _moodRailController = ScrollController();
  bool _canScrollBack = false;
  bool _canScrollForward = false;

  @override
  void initState() {
    super.initState();
    _moodRailController.addListener(_updateScrollButtons);
  }

  @override
  void dispose() {
    _moodRailController
      ..removeListener(_updateScrollButtons)
      ..dispose();
    super.dispose();
  }

  void _updateScrollButtons() {
    if (!_moodRailController.hasClients) {
      return;
    }
    final position = _moodRailController.position;
    final nextCanScrollBack = position.pixels > position.minScrollExtent + 8;
    final nextCanScrollForward = position.pixels < position.maxScrollExtent - 8;
    if (nextCanScrollBack == _canScrollBack &&
        nextCanScrollForward == _canScrollForward) {
      return;
    }
    setState(() {
      _canScrollBack = nextCanScrollBack;
      _canScrollForward = nextCanScrollForward;
    });
  }

  void _scheduleScrollButtonUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateScrollButtons();
      }
    });
  }

  void _scrollMoodRail(double direction) {
    if (!_moodRailController.hasClients) {
      return;
    }
    final position = _moodRailController.position;
    final target = (position.pixels + (direction * 280))
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    _moodRailController.animateTo(
      target,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final relatedMoods =
        (moodAdjacencyMap[widget.selectedMood] ?? const <MoodType>[])
            .where((mood) => mood != widget.selectedMood)
            .take(3)
            .toList(growable: false);
    final activeMoods = widget.selectedMoods.isEmpty
        ? {widget.selectedMood}
        : widget.selectedMoods.toSet();
    final selectionFull = activeMoods.length >= widget.maxSelectedMoods;
    final dark = context.isDarkMode;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;
        final desktopRail = constraints.maxWidth >= 720;
        final pillCompact = compact || desktopRail;
        final railHeight = compact ? 58.0 : (desktopRail ? 56.0 : 64.0);
        final showRelatedMoods =
            constraints.maxWidth < 720 && relatedMoods.isNotEmpty;
        _scheduleScrollButtonUpdate();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: railHeight,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ScrollConfiguration(
                    behavior: const MaterialScrollBehavior().copyWith(
                      dragDevices: PointerDeviceKind.values.toSet(),
                      scrollbars: false,
                    ),
                    child: SingleChildScrollView(
                      controller: _moodRailController,
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.only(
                        left: desktopRail ? 4 : 0,
                        right: desktopRail ? 52 : 0,
                      ),
                      child: Row(
                        children: [
                          for (
                            var index = 0;
                            index < MoodType.values.length;
                            index++
                          ) ...[
                            Builder(
                              builder: (context) {
                                final mood = MoodType.values[index];
                                return _MoodPill(
                                  mood: mood,
                                  selected: activeMoods.contains(mood),
                                  enabled:
                                      activeMoods.contains(mood) ||
                                      !selectionFull,
                                  compact: pillCompact,
                                  onTap: () => widget.onMoodSelected(mood),
                                );
                              },
                            ),
                            if (index < MoodType.values.length - 1)
                              SizedBox(width: desktopRail ? 8 : 10),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (desktopRail && _canScrollBack)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _MoodRailArrowButton(
                        icon: Icons.chevron_left_rounded,
                        tooltip: 'Previous moods',
                        onPressed: () => _scrollMoodRail(-1),
                      ),
                    ),
                  if (desktopRail && _canScrollForward)
                    Align(
                      alignment: Alignment.centerRight,
                      child: _MoodRailArrowButton(
                        icon: Icons.chevron_right_rounded,
                        tooltip: 'More moods',
                        onPressed: () => _scrollMoodRail(1),
                      ),
                    ),
                ],
              ),
            ),
            if (showRelatedMoods) ...[
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (
                      var index = 0;
                      index < relatedMoods.length;
                      index++
                    ) ...[
                      Builder(
                        builder: (context) {
                          final mood = relatedMoods[index];
                          final enabled =
                              activeMoods.contains(mood) || !selectionFull;
                          return ActionChip(
                            onPressed: enabled
                                ? () => widget.onMoodSelected(mood)
                                : null,
                            tooltip: enabled ? null : 'Pick up to 3 moods',
                            backgroundColor: moodSurface(
                              mood,
                              alpha: dark ? 0.28 : 0.2,
                            ),
                            disabledColor: context.glassSurface(
                              lightAlpha: 0.48,
                              darkAlpha: 0.48,
                            ),
                            label: Text(
                              mood.label,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: enabled
                                        ? context.mutedInk()
                                        : context.mutedInk().withValues(
                                            alpha: 0.56,
                                          ),
                                  ),
                            ),
                            avatar: SilvatorMascotAvatar(
                              mood: mood,
                              width: 22,
                              height: 22,
                            ),
                            side: BorderSide.none,
                          );
                        },
                      ),
                      if (index < relatedMoods.length - 1)
                        const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _MoodRailArrowButton extends StatelessWidget {
  const _MoodRailArrowButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDarkMode;
    final surface = dark
        ? const Color(0xFF10141B).withValues(alpha: 0.9)
        : const Color(0xFFEFF4F4).withValues(alpha: 0.94);
    final shadow = dark
        ? Colors.black.withValues(alpha: 0.28)
        : const Color(0xFF4C566A).withValues(alpha: 0.12);

    return Tooltip(
      message: tooltip,
      child: Container(
        width: 42,
        height: 42,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: surface,
          border: Border.all(color: context.surfaceStroke()),
          boxShadow: [
            BoxShadow(
              color: shadow,
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Icon(icon, color: context.brandInk(), size: 28),
          ),
        ),
      ),
    );
  }
}

class _MoodPill extends StatelessWidget {
  const _MoodPill({
    required this.mood,
    required this.selected,
    required this.enabled,
    required this.compact,
    required this.onTap,
  });

  final MoodType mood;
  final bool selected;
  final bool enabled;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = moodColors[mood]!;
    final dark = context.isDarkMode;
    final radius = BorderRadius.circular(compact ? 20 : 24);
    final motionDisabled = MediaQuery.disableAnimationsOf(context);
    final pillColor = selected
        ? accent.withValues(alpha: dark ? 0.82 : 0.9)
        : context.glassSurface(lightAlpha: 0.62, darkAlpha: 0.78);
    final avatarColor = selected
        ? (dark
              ? Colors.black.withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.26))
        : context.glassSurface(lightAlpha: 0.78, darkAlpha: 0.82);
    final textColor = selected
        ? const Color(0xFF1D2229)
        : Theme.of(context).textTheme.labelLarge?.color;

    final pill = AnimatedScale(
      scale: selected && enabled ? 1.02 : 1,
      duration: motionDisabled
          ? Duration.zero
          : const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      child: AnimatedContainer(
        duration: motionDisabled
            ? Duration.zero
            : const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: enabled
              ? pillColor
              : context.glassSurface(lightAlpha: 0.48, darkAlpha: 0.48),
          borderRadius: radius,
          border: Border.all(
            color: selected
                ? accent.withValues(alpha: dark ? 0.42 : 0.34)
                : context.surfaceStroke().withValues(alpha: enabled ? 1 : 0.5),
          ),
          boxShadow: selected && enabled
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: dark ? 0.18 : 0.24),
                    blurRadius: compact ? 16 : 24,
                    offset: Offset(0, compact ? 8 : 12),
                  ),
                ]
              : const [],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: enabled ? onTap : null,
            child: AnimatedOpacity(
              opacity: enabled ? 1 : 0.56,
              duration: motionDisabled
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 12 : 16,
                  vertical: compact ? 9 : 12,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: motionDisabled
                          ? Duration.zero
                          : const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      width: compact ? 26 : 34,
                      height: compact ? 26 : 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: avatarColor,
                      ),
                      alignment: Alignment.center,
                      clipBehavior: Clip.antiAlias,
                      child: SilvatorMascotAvatar(
                        mood: mood,
                        width: compact ? 26 : 34,
                        height: compact ? 26 : 34,
                      ),
                    ),
                    SizedBox(width: compact ? 8 : 10),
                    Text(
                      mood.label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                        fontSize: compact ? 14 : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (enabled) {
      return pill;
    }

    return Tooltip(message: 'Pick up to 3 moods', child: pill);
  }
}
