import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:window_manager/window_manager.dart';
import 'package:screen_retriever/screen_retriever.dart';

import '../../utils/utilities.dart';
import '../../utils/version.dart';

const kMenuItemKeyShow = 'show';
const kMenuItemKeyQuickStartGuide = 'quick-start-guide';
const kMenuItemKeyQuitApp = 'quit-app';

const kMenuSubItemKeyJoinDiscord = 'subitem-join-discord';
const kMenuSubItemKeyJoinQQGroup = 'subitem-join-qq';

class DesktopPopupPage extends StatefulWidget {
  const DesktopPopupPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _DesktopPopupPageState();
}

Widget build(BuildContext context) {
  // Your UI code here
  return Scaffold(
    appBar: AppBar(
      title: Text('Desktop Popup Page'),
    ),
    body: Center(
      child: Text('Hello, world!'),
    ),
  );
}

class _DesktopPopupPageState extends State<DesktopPopupPage>
    with WidgetsBindingObserver, TrayListener, WindowListener {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _textEditingController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final GlobalKey _bannersViewKey = GlobalKey();
  final GlobalKey _inputViewKey = GlobalKey();
  final GlobalKey _resultsViewKey = GlobalKey();

  Brightness _brightness = Brightness.light;
  Offset _lastShownPosition = Offset.zero;

  Version? _latestVersion;
  bool _isAllowedScreenCaptureAccess = true;
  bool _isAllowedScreenSelectionAccess = true;

  bool _isShowSourceLanguageSelector = false;
  bool _isShowTargetLanguageSelector = false;

  bool _querySubmitted = false;
  String _text = '';
  String? _textDetectedLanguage;
  bool _isTextDetecting = false;

  bool _lastShowTrayIcon = false;  // Initialize with default value
  String _lastAppLanguage = 'en';  // Initialize with default value

  void _handleChanged(bool showTrayIcon, String appLanguage) {
    bool trayIconUpdated = _lastShowTrayIcon != showTrayIcon ||
        _lastAppLanguage != appLanguage;

    _lastShowTrayIcon = showTrayIcon;
    _lastAppLanguage = appLanguage;

    if (trayIconUpdated) {
      _initTrayIcon();
    }

    if (mounted) setState(() {});
  }

  void _init() async {
    await _initTrayIcon();
    await Future.delayed(const Duration(milliseconds: 100));
    WindowOptions windowOptions = const WindowOptions(
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
      skipTaskbar: true,
      backgroundColor: Colors.transparent,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      if (kIsMacOS) {
        await windowManager.setVisibleOnAllWorkspaces(
          true,
          visibleOnFullScreen: true,
        );
      }
      if (kIsLinux || kIsWindows) {
        Display primaryDisplay = await screenRetriever.getPrimaryDisplay();
        Size windowSize = await windowManager.getSize();
        _lastShownPosition = Offset(
          primaryDisplay.size.width - windowSize.width - 50,
          50,
        );
        await windowManager.setPosition(_lastShownPosition);
      }
      await Future.delayed(const Duration(milliseconds: 100));
      await _windowShow(
        isShowBelowTray: kIsMacOS,
      );
    });
    setState(() {});
  }

  Future<void> _initTrayIcon() async {
    if (kIsWeb) return;

    String trayIconName = platformSelect<String>(
      () => 'tray_icon_black.png',
      windows: () => 'tray_icon_black.ico',
      linux: () => 'tray_icon.ico',
    );
    if (_brightness == Brightness.dark) {
      trayIconName = platformSelect<String>(
        () => 'tray_icon.png',
        windows: () => 'tray_icon.ico',
      );
    }

    await trayManager.destroy();
    await trayManager.setIcon(
      R.image(trayIconName),
      isTemplate: kIsMacOS ? true : false,
    );
    await Future.delayed(const Duration(milliseconds: 10));
    Menu menu = Menu(
      items: [
        MenuItem(
          label: "mylabel",
          // '${LocaleKeys.app_name.tr()} v${sharedEnv.appVersion} (BUILD ${sharedEnv.appBuildNumber})',
          disabled: true,
        ),
        MenuItem.separator(),
        if (kIsLinux)
          MenuItem(
            key: kMenuItemKeyShow,
            label: "label",
            // label: LocaleKeys.tray_context_menu_item_show.tr(),
          ),
        MenuItem(
          key: kMenuItemKeyQuickStartGuide,
          label: 'tray_context_menu.item_quick_start_guide'.tr(),
        ),
        MenuItem.submenu(
          label: 'tray_context_menu.item_discussion'.tr(),
          submenu: Menu(
            items: [
              MenuItem(
                key: kMenuSubItemKeyJoinDiscord,
                label:
                    'tray_context_menu.item_discussion_subitem_discord_server'
                        .tr(),
              ),
              MenuItem(
                key: kMenuSubItemKeyJoinQQGroup,
                label:
                    'tray_context_menu.item_discussion_subitem_qq_group'.tr(),
              ),
            ],
          ),
        ),
        MenuItem.separator(),
        MenuItem(
          key: kMenuItemKeyQuitApp,
          label: 'tray_context_menu.item_quit_app'.tr(),
        ),
      ],
    );
    await trayManager.setContextMenu(menu);
  }

  @override
  Widget build(BuildContext context) {
    // Your UI code here
    return Scaffold(
      appBar: AppBar(
        title: Text('Desktop Popup Page'),
      ),
      body: Center(
        child: Text('Hello, world!'),
      ),
    );
  }

  Future<void> _windowShow({
    bool isShowBelowTray = false,
  }) async {
    bool isAlwaysOnTop = await windowManager.isAlwaysOnTop();
    Size windowSize = await windowManager.getSize();

    if (kIsLinux) {
      await windowManager.setPosition(_lastShownPosition);
    }

    if (kIsMacOS && isShowBelowTray) {
      Rect? trayIconBounds = await trayManager.getBounds();
      if (trayIconBounds != null) {
        Size trayIconSize = trayIconBounds.size;
        Offset trayIconPosition = trayIconBounds.topLeft;

        Offset newPosition = Offset(
          trayIconPosition.dx - ((windowSize.width - trayIconSize.width) / 2),
          trayIconPosition.dy,
        );

        if (!isAlwaysOnTop) {
          await windowManager.setPosition(newPosition);
        }
      }
    }

    bool isVisible = await windowManager.isVisible();
    if (!isVisible) {
      await windowManager.show();
    } else {
      await windowManager.focus();
    }

    // Linux 下无法激活窗口临时解决方案
    if (kIsLinux && !isAlwaysOnTop) {
      await windowManager.setAlwaysOnTop(true);
      await Future.delayed(const Duration(milliseconds: 10));
      await windowManager.setAlwaysOnTop(false);
      await Future.delayed(const Duration(milliseconds: 10));
      await windowManager.focus();
    }
  }

  Future<void> _windowHide() async {
    await windowManager.hide();
  }

  void _windowResize() {
    if (Navigator.of(context).canPop()) return;
  }

  @override
  void onShortcutKeyDownShowOrHide() async {
    bool isVisible = await windowManager.isVisible();
    if (isVisible) {
      _windowHide();
    } else {
      _windowShow();
    }
  }

  @override
  void onShortcutKeyDownHide() async {
    _windowHide();
  }

  @override
  void onTrayIconMouseDown() async {
    _windowShow(isShowBelowTray: true);
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    switch (menuItem.key) {
      case kMenuItemKeyShow:
        await Future.delayed(Duration(milliseconds: 300));
        await _windowShow();
        break;
      case kMenuItemKeyQuickStartGuide:
        await launchUrlString('${sharedEnv.webUrl}/docs');
        break;
      case kMenuSubItemKeyJoinDiscord:
        await launchUrlString('https://discord.gg/yRF62CKza8');
        break;
      case kMenuSubItemKeyJoinQQGroup:
        await launchUrlString('https://jq.qq.com/?_wv=1027&k=vYQ5jW7y');
        break;
      case kMenuItemKeyQuitApp:
        await trayManager.destroy();
        exit(0);
    }
  }

  @override
  void onWindowFocus() async {
    _focusNode.requestFocus();
  }

  @override
  void onWindowBlur() async {
    _focusNode.unfocus();
    bool isAlwaysOnTop = await windowManager.isAlwaysOnTop();
    if (!isAlwaysOnTop) {
      windowManager.hide();
    }
  }

  @override
  void onWindowMove() async {
    _lastShownPosition = await windowManager.getPosition();
  }
}
