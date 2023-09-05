import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:window_manager/window_manager.dart';

import '../services/shortcut_service/shortcut_service.dart';
import '../utils/platform_util.dart';
import '../utils/r.dart';

const kMenuItemKeyShow = 'show';
const kMenuItemKeyQuitApp = 'quit-app';
const kMenuItemKeyQuickStartGuide = 'quick-start-guide';
const kMenuSubItemKeyJoinDiscord = 'subitem-join-discord';
const kMenuSubItemKeyJoinQQGroup = 'subitem-join-qq';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with
        WidgetsBindingObserver,
        ShortcutListener,
        TrayListener,
        WindowListener {
  final FocusNode _focusNode = FocusNode();

  Offset _lastShownPosition = Offset.zero;

  @override
  void initState() {
    WidgetsBinding.instance?.addObserver(this);
    if (kIsLinux || kIsMacOS || kIsWindows) {
      trayManager.addListener(this);
      windowManager.addListener(this);
      _init();
    }
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    if (kIsLinux || kIsMacOS || kIsWindows) {
      trayManager.removeListener(this);
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  void _init() async {
    await _initTrayIcon();
    await Future.delayed(const Duration(milliseconds: 100));
    WindowOptions windowOptions = const WindowOptions(
      size: Size(330, 410),
      // Set the width and height to 200x200
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
    //await _windowHide();  // Initially hide the window
    setState(() {});
  }

  Future<void> _initTrayIcon() async {
    String trayIconName = platformSelect<String>(
      () => 'tray_icon_black.png',
      windows: () => 'tray_icon_black.ico',
      linux: () => 'tray_icon.ico',
    );

    await trayManager.destroy();
    await trayManager.setIcon(
      R.image(trayIconName),
      isTemplate: kIsMacOS ? true : false,
    );
    await Future.delayed(const Duration(milliseconds: 10));
    Menu menu = Menu(
      items: [
        MenuItem(
          label: "1",
          disabled: true,
        ),
        MenuItem.separator(),
        if (kIsLinux) MenuItem(key: kMenuItemKeyShow, label: "2"),
        MenuItem(key: kMenuItemKeyQuickStartGuide, label: "3"),
        MenuItem.submenu(
          label: "another label",
          submenu: Menu(
            items: [
              MenuItem(key: kMenuSubItemKeyJoinDiscord, label: "4"),
              MenuItem(key: kMenuSubItemKeyJoinQQGroup, label: "5"),
            ],
          ),
        ),
        MenuItem.separator(),
        MenuItem(key: kMenuItemKeyQuitApp, label: "other"),
      ],
    );
    await trayManager.setContextMenu(menu);
  }

  Future<void> _windowShow({
    bool isShowBelowTray = false,
  }) async {
    try {
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
      print("isVisible: $isVisible");
      if (!isVisible) {
        try {
          await windowManager.show();
        } catch (e) {
          print("Error showing window: $e");
        }
      } else {
        await windowManager.focus();
      }

      if (kIsLinux && !isAlwaysOnTop) {
        await windowManager.setAlwaysOnTop(true);
        await Future.delayed(const Duration(milliseconds: 10));
        await windowManager.setAlwaysOnTop(false);
        await Future.delayed(const Duration(milliseconds: 10));
        await windowManager.focus();
      }
    } catch (e) {
      print("An error occurred in _windowShow: $e");
    }
  }

  Future<void> _windowHide() async {
    try {
      await windowManager.hide();
    } catch (e) {
      print("Error hiding window: $e");
    }
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    handleDismissed() => setState(() {});

    return PreferredSize(
      preferredSize: const Size.fromHeight(34),
      child: Container(
        padding: const EdgeInsets.only(left: 8, right: 8, top: 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: Container()),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Home Page Content'),
      ),
    );
  }

  /// shortcuts

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
    print("Tray icon clicked");
    bool isVisible = await windowManager.isVisible();
    print("isVisible: $isVisible");

    if (isVisible) {
      print("isVisible called");
      // _windowHide();
    } else {
      print("else for isVisible called");
      // _windowShow(isShowBelowTray: true);
    }
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    try {
      switch (menuItem.key) {
        case kMenuItemKeyShow:
          await Future.delayed(Duration(milliseconds: 300));
          await _windowShow();
          break;
        case kMenuItemKeyQuickStartGuide:
          await launchUrlString('https://bla.app/docs');
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
    } catch (e) {
      print("An error occurred in onTrayMenuItemClick: $e");
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

  @override
  void onShortcutKeyDownExtractFromClipboard() {
    // TODO: implement onShortcutKeyDownExtractFromClipboard
  }

  @override
  void onShortcutKeyDownExtractFromScreenCapture() {
    // TODO: implement onShortcutKeyDownExtractFromScreenCapture
  }

  @override
  void onShortcutKeyDownExtractFromScreenSelection() {
    // TODO: implement onShortcutKeyDownExtractFromScreenSelection
  }

  @override
  void onShortcutKeyDownSubmitWithMateEnter() {
    // TODO: implement onShortcutKeyDownSubmitWithMateEnter
  }

  @override
  void onShortcutKeyDownTranslateInputContent() {
    // TODO: implement onShortcutKeyDownTranslateInputContent
  }
}
