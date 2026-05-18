import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:wisely/src/application/ports/platform_ports.dart';
import 'package:wisely/src/application/state/wisely_controller.dart';
import 'package:wisely/src/data/repositories/hive_mood_journal_repository.dart';
import 'package:wisely/src/data/repositories/hive_quote_repository.dart';
import 'package:wisely/src/domain/entities/user_profile.dart';
import 'package:wisely/src/infrastructure/platform/app_exit_service.dart';
import 'package:wisely/src/infrastructure/platform/quote_actions_service.dart';
import 'package:wisely/src/infrastructure/platform/tray_service.dart';
import 'package:wisely/src/infrastructure/platform/widget_service.dart';
import 'package:wisely/src/presentation/screens/root_shell.dart';
import 'package:wisely/src/presentation/theme/wisely_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final supportDirectory = await getApplicationSupportDirectory();
  Hive.init(supportDirectory.path);

  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      size: Size(1120, 760),
      center: true,
      title: 'Selvator',
      minimumSize: Size(900, 620),
      titleBarStyle: TitleBarStyle.normal,
      windowButtonVisibility: true,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(
    ProviderScope(
      overrides: [
        quoteRepositoryProvider.overrideWith((ref) => HiveQuoteRepository()),
        moodJournalRepositoryProvider.overrideWith(
          (ref) => HiveMoodJournalRepository(),
        ),
        quoteWidgetPortProvider.overrideWith((ref) => WidgetService()),
        quoteActionsPortProvider.overrideWith((ref) => SystemQuoteActions()),
        appExitPortProvider.overrideWith((ref) => ProcessAppExit()),
        trayPortProvider.overrideWith((ref) {
          return TrayService(
            onAction: (action) {
              ref
                  .read(wiselyControllerProvider.notifier)
                  .handleTrayAction(action);
            },
            onMoodSelected: (mood) {
              ref.read(wiselyControllerProvider.notifier).selectMood(mood);
            },
          );
        }),
      ],
      child: const WiselyApp(),
    ),
  );
}

class WiselyApp extends ConsumerStatefulWidget {
  const WiselyApp({super.key});

  @override
  ConsumerState<WiselyApp> createState() => _WiselyAppState();
}

class _WiselyAppState extends ConsumerState<WiselyApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(wiselyControllerProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref
        .read(wiselyControllerProvider.notifier)
        .handleLifecycleChange(state.toWiselyPhase());
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(
      wiselyControllerProvider.select((s) => s.profile),
    );
    final tideSeason = ref.watch(
      wiselyControllerProvider.select((s) => s.tideSeason),
    );
    final timeBucket = ref.watch(
      wiselyControllerProvider.select((s) => s.timeBucket),
    );
    return MaterialApp(
      title: 'Selvator',
      debugShowCheckedModeBanner: false,
      themeMode: profile.themeMode.toFlutterThemeMode(),
      theme: WiselyTheme.light(season: tideSeason, bucket: timeBucket),
      darkTheme: WiselyTheme.dark(season: tideSeason, bucket: timeBucket),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(profile.textScale),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const RootShell(),
    );
  }
}

extension on AppLifecycleState {
  AppLifecyclePhase toWiselyPhase() {
    switch (this) {
      case AppLifecycleState.resumed:
        return AppLifecyclePhase.active;
      case AppLifecycleState.inactive:
        return AppLifecyclePhase.inactive;
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return AppLifecyclePhase.paused;
      case AppLifecycleState.detached:
        return AppLifecyclePhase.detached;
    }
  }
}

extension on AppThemeMode {
  ThemeMode toFlutterThemeMode() {
    switch (this) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }
}
