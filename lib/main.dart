import 'package:bharatapp/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

import 'providers/auth_provider.dart';
import 'providers/coin_provider.dart';
import 'screens/landing_page.dart';
import 'screens/home/home_page.dart';
import 'services/fcm_service.dart';

// 🔔 Background message handler (must be top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('🔔 Background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🔔 Set background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // 🔔 Initialize FCM Service
  await FCMService.initialize();

  runApp(const BharatDoorstepApp());
}

class BharatDoorstepApp extends StatelessWidget {
  const BharatDoorstepApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        /// CoinProvider depends on AuthProvider
        ChangeNotifierProxyProvider<AuthProvider, CoinProvider>(
          create: (_) => CoinProvider(''),
          update: (_, auth, previous) {
            String userId = '';

            if (auth.isTechnician && auth.technician != null) {
              userId = auth.technician!.uid;
            } else if (auth.isUser && auth.user != null) {
              userId = auth.user!.uid;
            }

            return CoinProvider(userId);
          },
        ),
      ],
      child: MaterialApp(
        title: 'Bharat Doorstep',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Roboto',
          scaffoldBackgroundColor: AppColors.bgLight,
          primaryColor: AppColors.primary,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
        home: const AuthChecker(),
      ),
    );
  }
}
class AuthChecker extends StatefulWidget {
  const AuthChecker({Key? key}) : super(key: key);

  @override
  State<AuthChecker> createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> {
  late Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = context.read<AuthProvider>().loadUser();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return FutureBuilder(
          future: _loadFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (authProvider.isLoggedIn) {
              return const HomePage();
            }

            return const LandingPage();
          },
        );
      },
    );
  }
}
