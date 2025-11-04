import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart'; // <-- You are correctly importing this

import 'services/auth_service.dart';
import 'services/db_service.dart';
import 'services/download_service.dart';
import 'screens/splash_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_users_screen.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'models/app_user.dart';
import 'utils/theme.dart';

void main() async {
  print("main: App starting");
  WidgetsFlutterBinding.ensureInitialized();
  print("main: WidgetsFlutterBinding initialized");

  // --- THIS IS THE FIX ---
  // You must pass the options from firebase_options.dart
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // ------------------------

  print("main: Firebase initialized"); // This line should now be reached
  await DownloadService().initialize();
  print("main: DownloadService initialized");
  runApp(const MyApp());
  print("main: runApp() called");
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    print("MyApp: build method called");
    return MultiProvider(
      providers: [
        Provider(create: (_) => DBService()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => DownloadService()),
      ],
      child: MaterialApp(
        title: 'GameHub',
        theme: AppTheme.themeData,
        home: const SplashScreen(),
        routes: {
          '/admin/dashboard': (_) => const AdminDashboardScreen(),
          '/admin/users': (_) => const AdminUsersScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    print("AuthWrapper: build method called");
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        if (authService.currentUser == null) {
          return const AuthScreen();
        } else {
          return const HomeScreen();
        }
      },
    );
  }
}
