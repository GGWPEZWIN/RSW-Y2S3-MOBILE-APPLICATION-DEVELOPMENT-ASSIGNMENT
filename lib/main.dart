import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'login.dart';
import 'services/google_sign_in_service.dart';
import 'services/fcm_service.dart';
import 'services/app_state_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    debugPrint('Firebase initialized successfully');

    await FCMService().initialize();
    debugPrint('FCM Service initialized');
  } catch (e) {
    debugPrint('Error initializing Firebase/FCM: $e');
  }

  try {
    await GoogleSignIn.instance.initialize();
    debugPrint('GoogleSignIn initialized successfully');
  } catch (e) {
    debugPrint('Error initializing GoogleSignIn: $e');
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppStateManager(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // We use a Builder here to get a 'newContext' that is
    // located UNDER the ChangeNotifierProvider in the widget tree.
    return Builder(
      builder: (newContext) {
        // Use newContext to find the AppStateManager
        final stateManager = Provider.of<AppStateManager>(newContext);

        return MaterialApp(
          title: 'JobBuddy',
          debugShowCheckedModeBanner: false,

          // THEME LOGIC
          themeMode: stateManager.themeMode,
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.blue,
            fontFamily: 'Poppins',
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.blue,
            fontFamily: 'Poppins',
            // In Dark Mode, backgrounds and text will switch automatically
          ),

          // LANGUAGE LOGIC
          locale: stateManager.locale,

          home: const LoginPage(),
        );
      },
    );
  }
}