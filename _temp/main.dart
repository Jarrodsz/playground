import 'dart:io';

import 'includes.dart';
import 'package:playground/services/services.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:rise_ui/rise_ui.dart' as rise_ui;
import 'package:window_manager/window_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';

Future<void> _ensureInitialized() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  if (kIsLinux || kIsMacOS || kIsWindows) {
    await windowManager.ensureInitialized();
  }

  if (kIsMacOS || kIsWindows) {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    LaunchAtStartup.instance.setup(
      appName: packageInfo.appName,
      appPath: Platform.resolvedExecutable,
    );
  }

  await initEnv();
}

void main() async {
  await _ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale(kLanguageEN),
      ],
      path: 'assets/locales',
      fallbackLocale: const Locale(kLanguageEN),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({
    Key? key,
  }) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  // Default configuration values
  final ThemeMode themeMode = ThemeMode.light;
  final String appLanguage = kLanguageEN;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _handleChanged() async {
    Locale oldLocale = context.locale;
    Locale newLocale = languageToLocale(appLanguage);
    if (newLocale != oldLocale) {
      await context.setLocale(newLocale);
    }

    await windowManager.setBrightness(
      themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light,
    );

    if (mounted) setState(() {});
  }

  Widget _buildHome(BuildContext context) {
    return const BootstrapPage();
  }

  @override
  Widget build(BuildContext context) {
    final botToastBuilder = BotToastInit();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      theme: lightThemeData,
      darkTheme: darkThemeData,
      themeMode: themeMode,
      builder: (context, child) {
        if (kIsLinux || kIsWindows) {
          child = Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(7),
                  topRight: Radius.circular(7),
                ),
                child: child,
              ),
              const DragToMoveArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 34,
                ),
              ),
            ],
          );
        }
        child = botToastBuilder(context, child);
        child = rise_ui.Theme(
          data: rise_ui.ThemeData(
            brightness: Brightness.light,  // Hardcoded to light mode
          ),
          child: child,
        );
        return child;
      },
      navigatorObservers: [BotToastNavigatorObserver()],
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: _buildHome(context),
    );
  }
}
