import 'package:bharatapp/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Make sure you have this file

import 'providers/auth_provider.dart';
import 'screens/landing_page.dart';
import 'screens/home/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with platform-specific options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const BharatDoorstepApp());
}

class BharatDoorstepApp extends StatelessWidget {
  const BharatDoorstepApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Bharat Doorstep',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Roboto',
          scaffoldBackgroundColor: AppColors.bgLight,
          primaryColor: AppColors.primary,
          colorScheme: ColorScheme.fromSwatch().copyWith(
            primary: AppColors.primary,
            secondary: AppColors.secondary,
            background: AppColors.bgLight,
            surface: AppColors.bgMedium,
            error: AppColors.primary,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onBackground: AppColors.textDark,
            onSurface: AppColors.textDark,
            onError: Colors.white,
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
          textTheme: const TextTheme(
            displayLarge: TextStyle(color: AppColors.textDark),
            displayMedium: TextStyle(color: AppColors.textDark),
            bodyLarge: TextStyle(color: AppColors.textMedium),
            bodyMedium: TextStyle(color: AppColors.textLight),
          ),
        ),
        home: const AuthChecker(),
      ),
    );
  }
}

class AuthChecker extends StatelessWidget {
  const AuthChecker({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Provider.of<AuthProvider>(context, listen: false).loadUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final authProvider = Provider.of<AuthProvider>(context);
        return authProvider.isLoggedIn
            ? const HomePage()
            : const LandingPage();
      },
    );
  }
}