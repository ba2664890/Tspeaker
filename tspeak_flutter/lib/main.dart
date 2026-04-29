import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/inscription_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/user_service.dart';
import 'services/speech_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => ApiService(baseUrl: 'http://localhost:8001/api/v1')),
        RepositoryProvider(create: (context) => AuthService(context.read<ApiService>())),
        RepositoryProvider(create: (context) => UserService(context.read<ApiService>())),
        RepositoryProvider(create: (context) => SpeechService(context.read<ApiService>())),
      ],
      child: const TSpeakApp(),
    ),
  );
}

class TSpeakApp extends StatelessWidget {
  static final navigatorKey = GlobalKey<NavigatorState>();
  const TSpeakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'T.Speak',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/inscription': (context) => const InscriptionScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
