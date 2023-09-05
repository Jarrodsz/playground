import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:playground/pages/bootstrap.dart';
import 'package:playground/utils/env.dart';
import 'package:playground/utils/platform_util.dart';
import 'package:window_manager/window_manager.dart';
import 'package:rise_ui/rise_ui.dart' as rise_ui;
import 'package:playground/utils/language_util.dart';


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
  // await initLocalDb();
}


Future<void> main() async {

  await _ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale(kLanguageEN),
        Locale(kLanguageZH),
      ],
      path: 'resources/langs',
      assetLoader: false,
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

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildHome(BuildContext context) {
    return const BootstrapPage();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        if (kIsLinux || kIsWindows) {
          child = Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(7),
                  topRight: Radius.circular(7),
                ),
                child: child ?? Container(),  // Added null-aware operator here
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
        child = rise_ui.Theme(
          data: rise_ui.ThemeData(brightness: Brightness.light),
          child: child ?? Container(),  // Added null-aware operator here
        );
        return child;
      },
      home: _buildHome(context),
    );
  }
}
