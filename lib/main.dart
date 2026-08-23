import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/app_theme.dart';
import 'firebase_options.dart';
import 'models/user_profile.dart';
import 'screens/auth_screen.dart';
import 'screens/home_shell.dart';
import 'screens/onboarding_screen.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'widgets/shared_ui.dart';

const _isSideloadBuild = bool.fromEnvironment('NOURISH_SIDELOAD');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (!_isSideloadBuild) {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
    );
  }
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppPalette.canvas,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const NourishApp());
}

class NourishApp extends StatelessWidget {
  const NourishApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nourish',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  late final AuthService _authService;
  late final FirestoreService _firestoreService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _firestoreService = FirestoreService();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const LoadingView(label: 'Opening your space…');
        }
        final user = authSnapshot.data;
        if (user == null) return AuthScreen(authService: _authService);

        return StreamBuilder<UserProfile?>(
          stream: _firestoreService.watchProfile(user.uid),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.hasError) {
              return _CloudErrorView(onSignOut: _authService.signOut);
            }
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const LoadingView();
            }
            final profile = profileSnapshot.data;
            if (profile == null || !profile.onboardingComplete) {
              final initial =
                  profile ??
                  UserProfile.empty(
                    uid: user.uid,
                    email: user.email ?? '',
                    displayName: user.displayName,
                  );
              return OnboardingScreen(
                initialProfile: initial,
                onComplete: _firestoreService.saveProfile,
              );
            }

            return HomeShell(
              profile: profile,
              authService: _authService,
              firestoreService: _firestoreService,
              userPhotoUrl: user.photoURL,
            );
          },
        );
      },
    );
  }
}

class _CloudErrorView extends StatelessWidget {
  const _CloudErrorView({required this.onSignOut});
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: AppPalette.coral.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cloud_off_rounded, size: 34),
              ),
              const SizedBox(height: 20),
              Text(
                'Couldn’t reach your plan',
                style: context.text.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Check your connection, then reopen the app. Your account is still safe.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppPalette.muted),
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: onSignOut,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Return to sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
