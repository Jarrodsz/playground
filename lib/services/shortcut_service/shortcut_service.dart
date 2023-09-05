import 'package:hotkey_manager/hotkey_manager.dart';

import 'package:playground/utils/platform_util.dart';

abstract mixin class ShortcutListener {
  void onShortcutKeyDownShowOrHide();
  void onShortcutKeyDownHide();
  void onShortcutKeyDownExtractFromScreenSelection();
  void onShortcutKeyDownExtractFromScreenCapture();
  void onShortcutKeyDownExtractFromClipboard();
  void onShortcutKeyDownTranslateInputContent();
  void onShortcutKeyDownSubmitWithMateEnter();
}

class ShortcutService {
  ShortcutService._();

  /// The shared instance of [ShortcutService].
  static final ShortcutService instance = ShortcutService._();

  ShortcutListener? _listener;

  // Default shortcut settings (replace these with your own defaults)
  final defaultShortcutInputSettingSubmitWithMetaEnter = "Ctrl+Alt+Enter";
  final defaultShortcutShowOrHide = "Ctrl+Alt+H";
  final defaultShortcutHide = "Ctrl+Alt+J";
  final defaultShortcutExtractFromScreenSelection = "Ctrl+Alt+S";
  final defaultShortcutExtractFromScreenCapture = "Ctrl+Alt+C";
  final defaultShortcutExtractFromClipboard = "Ctrl+Alt+V";
  final defaultShortcutTranslateInputContent = "Ctrl+Alt+T";

  void setListener(ShortcutListener? listener) {
    _listener = listener;
  }

  void start() async {
    await hotKeyManager.unregisterAll();
    await hotKeyManager.register(
      defaultShortcutInputSettingSubmitWithMetaEnter as HotKey,
      keyDownHandler: (_) {
        _listener?.onShortcutKeyDownSubmitWithMateEnter();
      },
    );
    await hotKeyManager.register(
      defaultShortcutShowOrHide as HotKey,
      keyDownHandler: (_) {
        _listener?.onShortcutKeyDownShowOrHide();
      },
    );
    await hotKeyManager.register(
      defaultShortcutHide as HotKey,
      keyDownHandler: (_) {
        _listener?.onShortcutKeyDownHide();
      },
    );
    await hotKeyManager.register(
      defaultShortcutExtractFromScreenSelection as HotKey,
      keyDownHandler: (_) {
        _listener?.onShortcutKeyDownExtractFromScreenSelection();
      },
    );
    if (!kIsLinux) {
      await hotKeyManager.register(
        defaultShortcutExtractFromScreenCapture as HotKey,
        keyDownHandler: (_) {
          _listener?.onShortcutKeyDownExtractFromScreenCapture();
        },
      );
    }
    await hotKeyManager.register(
      defaultShortcutExtractFromClipboard as HotKey,
      keyDownHandler: (_) {
        _listener?.onShortcutKeyDownExtractFromClipboard();
      },
    );
    if (!kIsLinux) {
      await hotKeyManager.register(
        defaultShortcutTranslateInputContent as HotKey,
        keyDownHandler: (_) {
          _listener?.onShortcutKeyDownTranslateInputContent();
        },
      );
    }
  }

  void stop() {
    hotKeyManager.unregisterAll();
  }
}
