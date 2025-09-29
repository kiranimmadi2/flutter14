import 'dart:async';
// ignore: avoid_web_libraries_in_flutter

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';
// Call screen imports removed
import 'services/auth_service.dart';
import 'services/profile_service.dart';
import 'services/user_manager.dart';
import 'services/notification_service.dart';
import 'services/conversation_service.dart';
import 'services/location_service.dart';
import 'services/connectivity_service.dart';
import 'providers/theme_provider.dart';
// Call service imports removed
import 'utils/app_optimizer.dart';
import 'utils/memory_manager.dart';

// Background message handler - MUST be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if not already initialized
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  debugPrint('Background message received: ${message.data}');
  
  // Call notification handling removed
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  
  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize Firebase with optimizations
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Set up FCM background handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  // Initialize app optimizer
  await AppOptimizer.initialize();
  
  // Initialize memory manager
  MemoryManager().initialize();
  
  // Initialize services sequentially
  UserManager().initialize();
  await NotificationService().initialize();
  await ConnectivityService().initialize();
  // Call service initialization removed
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Supper',
            theme: themeProvider.themeData,
            home: const AuthWrapper(),
            // Call routes removed
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final profileService = ProfileService();
    final locationService = LocationService();
    
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          // Ensure profile exists when user is logged in
          profileService.ensureProfileExists();
          
          // Initialize location service (will ask permission only first time)
          locationService.initializeLocation();
          
          // Clean up any duplicate conversations on login
          ConversationService().cleanupDuplicateConversations();
          
          return const MainNavigationScreen();
        }
        
        return const LoginScreen();
      },
    );
  }
}
