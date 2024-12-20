import 'dart:async';
import 'package:offline17000ft/helper/shared_prefernce.dart';
import 'package:offline17000ft/home/home_screen.dart';
import 'package:offline17000ft/login/login_screen.dart';
import 'package:offline17000ft/splash/splash_screen.dart';
import 'package:offline17000ft/utils/dependency_injection.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';
import 'package:offline17000ft/theme/theme_constants.dart';
import 'package:offline17000ft/theme/theme_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  DependencyInjection.init();

  runApp(const MyApp());
}

ThemeManager themeManager = ThemeManager();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool? _isLoggedIn;

  @override
  void initState() {
    super.initState();
    themeManager.addListener(_themeListener);
    _initializeApp();
  }

  @override
  void dispose() {
    themeManager.removeListener(_themeListener);
    super.dispose();
  }

  void _themeListener() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initializeApp() async {
    // Add a short delay to allow the splash screen to display briefly
    await Future.delayed(const Duration(seconds: 4));

    // Check login state and store it in _isLoggedIn
    final isLoggedIn = await SharedPreferencesHelper.getLoginState();

    // Update the state and navigate based on login state
    setState(() {
      _isLoggedIn = isLoggedIn;
    });

    _navigateBasedOnAuth();
  }

  void _navigateBasedOnAuth() {
    // Navigate to the appropriate screen based on login state
    if (_isLoggedIn == true) {
      Get.offAll(() => const HomeScreen());
    } else {
      Get.offAll(() => const LoginScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'offline17000ft',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeManager.themeMode,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
