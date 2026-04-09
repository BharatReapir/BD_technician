import 'constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

import 'providers/auth_provider.dart';
import 'providers/coin_provider.dart';
import 'screens/technician_login_page.dart';
import 'screens/technician_home_page.dart';
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

  runApp(const BDRTechnicianApp());
}

class BDRTechnicianApp extends StatelessWidget {
  const BDRTechnicianApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        /// CoinProvider depends on AuthProvider (for technician earnings)
        ChangeNotifierProxyProvider<AuthProvider, CoinProvider>(
          create: (_) => CoinProvider(''),
          update: (_, auth, previous) {
            String userId = '';

            if (auth.isTechnician && auth.technician != null) {
              userId = auth.technician!.uid;
            }

            return CoinProvider(userId);
          },
        ),
      ],
      child: MaterialApp(
        title: 'BDR Technician',
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
          textTheme: const TextTheme().apply(
            fontFamilyFallback: ['Noto Sans', 'sans-serif'],
          ),
        ),
        home: const TechnicianAuthChecker(),
      ),
    );
  }
}

class TechnicianAuthChecker extends StatefulWidget {
  const TechnicianAuthChecker({Key? key}) : super(key: key);

  @override
  State<TechnicianAuthChecker> createState() => _TechnicianAuthCheckerState();
}

class _TechnicianAuthCheckerState extends State<TechnicianAuthChecker> {
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

            // ✅ TECHNICIAN APP: Only allow technician login
            if (authProvider.isLoggedIn && authProvider.isTechnician) {
              return const TechnicianHomePage();
            }

            // Show error if user account tries to login
            if (authProvider.isLoggedIn && authProvider.isUser) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('This account is not registered as a technician. Please use the Customer App.'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 3),
                  ),
                );
                authProvider.logout();
              });
            }

            return const TechnicianLoginPage();
          },
        );
      },
    );
  }
}
