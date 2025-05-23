import 'package:downloadsplatform/Models/WidgetsBindingObserver.dart';
import 'package:downloadsplatform/Models/auth_provider.dart';
import 'package:downloadsplatform/screens/BottomBar/DownloadProgressScreen.dart';
import 'package:downloadsplatform/screens/BottomBar/FingerprintScreen.dart';
import 'package:downloadsplatform/screens/BottomBar/PasswordInputScreen.dart';
import 'package:downloadsplatform/screens/BottomBar/SecuritySettingsScreen.dart';
import 'package:downloadsplatform/screens/CreateAccountScreen.dart';
import 'package:downloadsplatform/screens/HomeScreen.dart';
import 'package:downloadsplatform/screens/LoginScreen.dart';
import 'package:downloadsplatform/screens/OnboardingScreen1.dart';
import 'package:downloadsplatform/screens/OnboardingScreen2.dart';
import 'package:downloadsplatform/screens/OnboardingScreen3.dart';
import 'package:downloadsplatform/screens/ForgotPasswordScreen.dart';
import 'package:downloadsplatform/screens/ResetPasswordScreen.dart';
import 'package:downloadsplatform/screens/SplashScreen.dart';
import 'package:downloadsplatform/screens/VerifyPasswordCodeScreen.dart';
import 'package:downloadsplatform/screens/CompleteProfileScreen.dart';
import 'package:downloadsplatform/screens/WelcomeScreen.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'dart:ui';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set up global error handlers for all Flutter errors
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };

  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, stack) {
    // Log Firebase initialization errors but don't crash
    print("Firebase initialization error: $e");
    FirebaseCrashlytics.instance.recordError(e, stack, fatal: false);
  }

  // Initialize SharedPreferences and auth provider in try-catch blocks
  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (e, stack) {
    print("SharedPreferences initialization error: $e");
    FirebaseCrashlytics.instance.recordError(e, stack, fatal: false);
  }

  final authProvider = UserProvider();
  try {
    await authProvider.loadUserData();
  } catch (e, stack) {
    print("User data loading error: $e");
    FirebaseCrashlytics.instance.recordError(e, stack, fatal: false);
  }

  final tracker = AppLifecycleTracker();
  WidgetsBinding.instance.addObserver(tracker);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => authProvider),
        ChangeNotifierProvider(create: (_) => DownloadManager()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppLifecycleTracker _appLifecycleTracker = AppLifecycleTracker();

  @override
  void initState() {
    super.initState();
    _appLifecycleTracker.initialize(context);
  }

  @override
  void dispose() {
    _appLifecycleTracker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<UserProvider>(context, listen: false);

    return MaterialApp(
      title: 'Download Platform',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromRGBO(58, 93, 248, 1),
        ),
        useMaterial3: true,
      ),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: LockScreen(child: HomeScreen()),
      ),
      routes: {
        '/onboarding1': (context) => OnboardingScreen1(),
        '/onboarding2': (context) => OnboardingScreen2(),
        '/onboarding3': (context) => OnboardingScreen3(),
        '/createAccount': (context) => CreateAccountScreen(),
        '/login': (context) => LoginScreen(),
        '/forgotPassword': (context) => ForgotPasswordScreen(),
        '/verifyPasswordCode':
            (context) => VerifyPasswordCodeScreen(email: '', type: ''),
        '/resetPassword': (context) => ResetPasswordScreen(),
        '/completeProfile': (context) => CompleteProfileScreen(),
        '/welcome': (context) => WelcomeScreen(),
        '/home':
            (context) => Directionality(
              textDirection: TextDirection.rtl,
              child: HomeScreen(),
            ),
      },
    );
  }
}
