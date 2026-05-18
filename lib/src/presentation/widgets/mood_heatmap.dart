import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wisely/src/domain/entities/mood_type.dart';
import 'package:wisely/src/presentation/theme/wisely_theme.dart';

class MoodHeatmap extends StatelessWidget {
  const MoodHeatmap({super.key, required this.entries, this.filterMood});

  final Map<String, int> entries;
  final MoodType? filterMood;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dates = List<DateTime>.generate(
      30,
      (index) => DateTime(now.year, now.month, now.day - (29 - index)),
    );
    final maxCount = _maxCount(dates);
    final accent = filterMood == null
        ? Theme.of(context).colorScheme.primary
        : moodColors[filterMood] ?? Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '30-day mood heatmap',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final date in dates)
              Tooltip(
                message:
                    '${DateFormat.MMMd().format(date)}: ${_countForDate(date)} mood taps',
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: accent.withValues(
                      alpha: 0.18 + ((_countForDate(date) / maxCount) * 0.72),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  int _maxCount(List<DateTime> dates) {
    final counts = dates.map(_countForDate).toList(growable: false);
    final maxCount = counts.fold<int>(
      1,
      (current, next) => next > current ? next : current,
    );
    return maxCount == 0 ? 1 : maxCount;
  }

  int _countForDate(DateTime date) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    if (filterMood != null) {
      return entries['$dateKey|${filterMood!.name}'] ?? 0;
    }
    return entries.entries
        .where((entry) => entry.key.startsWith(dateKey))
        .fold<int>(0, (sum, entry) => sum + entry.value);
  }
}
