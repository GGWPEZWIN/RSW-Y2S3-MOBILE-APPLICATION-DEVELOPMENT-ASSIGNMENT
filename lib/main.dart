import 'package:assignment/services/app_state_manager.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart'; // 1. Add this import
import 'l10n/app_localizations.dart';
import 'login.dart';
import 'services/google_sign_in_service.dart';
import 'services/fcm_service.dart';

//global value for english default
final ValueNotifier<Locale> appLocale = ValueNotifier(const Locale('en'));

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    await Firebase.initializeApp();
    await FCMService().initialize();
    await GoogleSignInService.initialize();
    debugPrint('All services initialized successfully');
  } catch (e) {
    debugPrint('Initialization Error: $e');
  }

  runApp(
    // 2. Wrap the app in the Provider
    ChangeNotifierProvider(
      create: (context) => AppStateManager(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Get the manager from Provider
    final stateManager = Provider.of<AppStateManager>(context, listen: false);

    // 2. Pass it to your FCM service
    FCMService().attachStateManager(stateManager);

    // 3. Use Consumer to listen for language changes
    return Consumer<AppStateManager>(
      builder: (context, stateManager, child) {
        return MaterialApp(
          title: 'JobBuddy',
          debugShowCheckedModeBanner: false,

          // 4. Get locale from stateManager
          locale: stateManager.locale,

          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          supportedLocales: const [
            Locale('en'),
            Locale('ms'),
            Locale('zh'),
          ],

          theme: ThemeData(
            primarySwatch: Colors.blue,
            fontFamily: 'Poppins',
            scaffoldBackgroundColor: Colors.white,
          ),

          home: const LoginPage(),
        );
      },
    );
  }
}