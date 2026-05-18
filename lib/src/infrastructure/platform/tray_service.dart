import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:wisely/src/application/ports/platform_ports.dart';
import 'package:wisely/src/domain/entities/mood_type.dart';

class TrayService with TrayListener implements TrayPort {
  TrayService({
    required ValueChanged<TrayAction> onAction,
    required ValueChanged<MoodType> onMoodSelected,
  }) : _onAction = onAction,
       _onMoodSelected = onMoodSelected;

  final ValueChanged<TrayAction> _onAction;
  final ValueChanged<MoodType> _onMoodSelected;

  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (!Platform.isWindows || _initialized) {
      return;
    }
    trayManager.addListener(this);
    final iconPath = _resolveWindowsTrayIconPath();
    if (iconPath != null) {
      try {
        await trayManager.setIcon(iconPath);
      } catch (error, stackTrace) {
        if (kDebugMode) {
          debugPrint('Tray icon init failed: $error');
          debugPrintStack(stackTrace: stackTrace);
        }
      }
    }
    _initialized = true;
  }

  @override
  Future<void> dispose() async {
    if (!Platform.isWindows || !_initialized) {
      return;
    }
    trayManager.removeListener(this);
    await trayManager.destroy();
    _initialized = false;
  }

  @override
  Future<void> update({
    required String previewText,
    required MoodType selectedMood,
  }) async {
    if (!Platform.isWindows || !_initialized) {
      return;
    }

    await trayManager.setToolTip(previewText);
    await trayManager.setContextMenu(
      Menu(
        items: [
          MenuItem(key: 'preview', label: previewText, disabled: true),
          MenuItem.separator(),
          MenuItem(key: 'next_quote', label: 'Next quote'),
          MenuItem.submenu(
            key: 'change_mood',
            label: 'Change mood',
            submenu: Menu(
              items: [
                for (final mood in MoodType.values)
                  MenuItem.checkbox(
                    key: 'mood_${mood.name}',
                    label: mood.label,
                    checked: mood == selectedMood,
                  ),
              ],
            ),
          ),
          MenuItem(key: 'copy_quote', label: 'Copy quote'),
          MenuItem.separator(),
          MenuItem(key: 'open_app', label: 'Open Selvator'),
          MenuItem(key: 'quit_app', label: 'Quit'),
        ],
      ),
    );
  }

  @override
  void onTrayIconMouseDown() {
    if (Platform.isWindows) {
      trayManager.popUpContextMenu();
    }
  }

  @override
  Future<void> onTrayMenuItemClick(MenuItem menuItem) async {
    if (kDebugMode) {
      debugPrint('Tray click: ${menuItem.key}');
    }
    final key = menuItem.key ?? '';
    if (key == 'next_quote') {
      _onAction(TrayAction.nextQuote);
      return;
    }
    if (key == 'copy_quote') {
      _onAction(TrayAction.copyQuote);
      return;
    }
    if (key == 'open_app') {
      _onAction(TrayAction.openApp);
      await windowManager.show();
      await windowManager.focus();
      return;
    }
    if (key == 'quit_app') {
      _onAction(TrayAction.quitApp);
      return;
    }
    if (key.startsWith('mood_')) {
      final mood = MoodType.fromKey(key.replaceFirst('mood_', ''));
      _onMoodSelected(mood);
      return;
    }
  }

  String? _resolveWindowsTrayIconPath() {
    final executableDir = File(Platform.resolvedExecutable).parent;
    final candidates = <File>[
      File('${Directory.current.path}\\assets\\icons\\wisely_tray.ico'),
      File(
        '${executableDir.path}\\data\\flutter_assets\\assets\\icons\\wisely_tray.ico',
      ),
      File(
        '${executableDir.parent.path}\\data\\flutter_assets\\assets\\icons\\wisely_tray.ico',
      ),
    ];
    for (final candidate in candidates) {
      if (candidate.existsSync()) {
        return candidate.path;
      }
    }
    return null;
  }
}
