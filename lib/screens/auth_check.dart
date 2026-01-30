import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../utils.dart'; // Import utils to use the functions

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> with WidgetsBindingObserver {
  bool _isDeveloperMode = false;
  bool _isEmulator = false;
  bool _isLoading = true; // Start with a loading state

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _performChecks();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // When the app resumes from the background, re-run the checks.
    if (state == AppLifecycleState.resumed) {
      _performChecks();
    }
  }

  Future<void> _performChecks() async {
    // Ensure the widget is still mounted before updating the state.
    if (!mounted) return;

    setState(() {
      _isLoading = true; // Show loading indicator while checking
    });

    // Perform all checks concurrently.
    final results = await Future.wait([
      isDeveloperModeEnabled(),
      isUsbDebuggingEnabled(),
      isEmulator(),
    ]);

    final isDevMode = results[0] || results[1]; // Combine Developer Mode and USB Debugging
    final isEmu = results[2];

    // Check again if the widget is still in the tree before setting state.
    if (mounted) {
      setState(() {
        _isDeveloperMode = isDevMode;
        _isEmulator = isEmu;
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading screen while checks are running.
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Show blocking screens if necessary.
    if (_isEmulator) {
      return const EmulatorBlockedScreen();
    }
    if (_isDeveloperMode) {
      return const DeveloperModeBlockedScreen();
    }

    // If all checks pass, proceed with authentication state.
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          // If user is logged in, go to DeviceCheckScreen first.
          return const DeviceCheckScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
