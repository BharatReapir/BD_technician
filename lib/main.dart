import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/landing_page.dart';
import 'screens/home/home_page.dart';

void main() {
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
          primarySwatch: Colors.green,
          fontFamily: 'Roboto',
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
        return authProvider.isLoggedIn ? const HomePage() : const LandingPage();
      },
    );
  }
}