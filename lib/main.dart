
import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:doctors_path_academy/admin_screen.dart';
import 'package:doctors_path_academy/lectures_screen.dart';
import 'package:doctors_path_academy/my_certificates_screen.dart';
import 'package:doctors_path_academy/screens/profile_screen.dart';
import 'package:doctors_path_academy/user_provider.dart';
import 'package:doctors_path_academy/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'screens/auth_check.dart';

// ======================================
// ======== Theme Provider
// ======================================
class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  final String themeKey = "is_dark_mode";

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(themeKey) ?? false;
    notifyListeners();
  }

  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(themeKey, _isDarkMode);
    notifyListeners();
  }
}

// ======================================
// ======== Blocking Screens
// ======================================
class EmulatorBlockedScreen extends StatelessWidget {
  const EmulatorBlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF121212),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.report_problem_outlined, size: 80, color: Colors.red),
              SizedBox(height: 20),
              Text("Emulator Detected", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              SizedBox(height: 10),
              Text("This app cannot be run on an emulator.", style: TextStyle(fontSize: 16, color: Colors.white70), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class DeveloperModeBlockedScreen extends StatelessWidget {
  const DeveloperModeBlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF121212),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.developer_mode, size: 80, color: Colors.orange),
              SizedBox(height: 20),
              Text("Developer Mode Enabled", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              SizedBox(height: 10),
              Text("For security reasons, please disable Developer Options to continue using the app.", style: TextStyle(fontSize: 16, color: Colors.white70), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================================
// ======== Account Blocked Screen
// ======================================
class AccountBlockedScreen extends StatelessWidget {
  const AccountBlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block, size: 80, color: Colors.red),
              const SizedBox(height: 20),
              const Text("Account Blocked", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 10),
              const Text("Your account has been temporarily blocked due to suspicious activity. Please contact support.", style: TextStyle(fontSize: 16, color: Colors.white70), textAlign: TextAlign.center),
              const SizedBox(height: 30),
              ElevatedButton(onPressed: () => exit(0), child: const Text('Exit App'))
            ],
          ),
        ),
      ),
    );
  }
}

// ======================================
// ======== No Internet Screen
// ======================================
class NoInternetScreen extends StatelessWidget {
  final VoidCallback onRetry;
  const NoInternetScreen({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, size: 80, color: Colors.grey),
              const SizedBox(height: 20),
              const Text("No Internet Connection", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text("Please check your internet connection and try again.", style: TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.center),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text("Retry"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================================
// ======== Main
// ======================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await FirebaseAppCheck.instance.activate(
    androidProvider: kReleaseMode ? AndroidProvider.playIntegrity : AndroidProvider.debug,
  );
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => UserProvider()),
      ],
      child: const DoctorsPathAcademy(),
    ),
  );
}

class DoctorsPathAcademy extends StatelessWidget {
  const DoctorsPathAcademy({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: "Doctor's Path Academy",
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: Colors.grey[100],
            fontFamily: 'Poppins',
            appBarTheme: const AppBarTheme(
              elevation: 0,
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.black,
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Colors.white,
              selectedItemColor: Colors.blue,
              unselectedItemColor: Colors.grey,
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: const Color(0xFF121212),
            fontFamily: 'Poppins',
            appBarTheme: const AppBarTheme(
              elevation: 0,
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
            ),
            cardColor: const Color(0xFF1E1E1E),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Color(0xFF1E1E1E),
              selectedItemColor: Colors.blue,
              unselectedItemColor: Colors.grey,
            ),
          ),
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const AuthCheck(),
        );
      },
    );
  }
}

// ======================================
// ======== App Protector
// ======================================
class AppProtector extends StatefulWidget {
  final Widget child;
  const AppProtector({super.key, required this.child});

  @override
  State<AppProtector> createState() => _AppProtectorState();
}

class _AppProtectorState extends State<AppProtector> with WidgetsBindingObserver {
  bool _isDeveloperMode = false;
  bool _isEmulator = false;
  bool _isChecking = true;

  Timer? _batteryCheckTimer;
  int? _initialBatteryLevel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _performChecks();
    _startBatteryMonitor();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _batteryCheckTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _performChecks();
      _startBatteryMonitor(); // Restart monitor when app resumes
    } else if (state == AppLifecycleState.paused) {
      _batteryCheckTimer?.cancel(); // Stop monitor when app is paused
    }
  }

  Future<void> _startBatteryMonitor() async {
    // Get initial battery state
    final initialStatus = await getBatteryStatus();
    _initialBatteryLevel = initialStatus['level'];

    _batteryCheckTimer?.cancel(); // Cancel any existing timer
    _batteryCheckTimer = Timer(const Duration(minutes: 30), () async {
      final currentStatus = await getBatteryStatus();
      final currentLevel = currentStatus['level'];
      final isCharging = currentStatus['isCharging'];

      // The condition to trigger the block
      if (currentLevel == _initialBatteryLevel && !(currentLevel == 100 && isCharging)) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          try {
            await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'inactive': 'yes'});
            // Force close the app
            exit(0);
          } catch (e) {
            // Handle potential Firestore errors
          }
        }
      }
    });
  }

  Future<void> _performChecks() async {
    if (!mounted) return;
    setState(() => _isChecking = true);

    final results = await Future.wait([
      isDeveloperModeEnabled(),
      isUsbDebuggingEnabled(),
      isEmulator(),
    ]);

    final isDevMode = results[0] || results[1];
    final isEmu = results[2];

    if (mounted) {
      setState(() {
        _isDeveloperMode = isDevMode;
        _isEmulator = isEmu;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_isEmulator) {
      return const EmulatorBlockedScreen();
    }
    if (_isDeveloperMode) {
      return const DeveloperModeBlockedScreen();
    }
    return widget.child;
  }
}

// ======================================
// ======== Device Check Screen
// ======================================
class DeviceCheckScreen extends StatefulWidget {
  const DeviceCheckScreen({super.key});

  @override
  State<DeviceCheckScreen> createState() => _DeviceCheckScreenState();
}

class _DeviceCheckScreenState extends State<DeviceCheckScreen> with WidgetsBindingObserver {
  bool _isDeveloperMode = false;
  bool _isEmulator = false;
  bool _hasInternet = true;
  bool _isChecking = true;
  bool _isAccountBlocked = false; // New state for blocked accounts

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
    if (state == AppLifecycleState.resumed) {
      _performChecks();
    }
  }

  Future<void> _performChecks() async {
    if (!mounted) return;
    setState(() {
      _isChecking = true;
      _hasInternet = true;
    });

    final connectivityResult = await (Connectivity().checkConnectivity());
    final hasConnection = connectivityResult.contains(ConnectivityResult.mobile) || connectivityResult.contains(ConnectivityResult.wifi);

    if (!hasConnection) {
      if (mounted) {
        setState(() {
          _hasInternet = false;
          _isChecking = false;
        });
      }
      return;
    }

    final results = await Future.wait([
      isDeveloperModeEnabled(),
      isUsbDebuggingEnabled(),
      isEmulator(),
    ]);

    final isDevMode = results[0] || results[1];
    final isEmu = results[2];

    if (mounted) {
      setState(() {
        _isDeveloperMode = isDevMode;
        _isEmulator = isEmu;
      });
    }

    if (isDevMode || isEmu) {
      setState(() => _isChecking = false);
      return;
    }

    await _verifyDevice();

    if (mounted) {
      setState(() => _isChecking = false);
    }
  }

  Future<void> _verifyDevice() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final userDoc = await userDocRef.get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;

        // Check if the account is inactive/blocked
        if (userData['inactive'] == 'yes') {
          setState(() => _isAccountBlocked = true);
          await FirebaseAuth.instance.signOut(); // Sign out the user
          return;
        }

        final currentDeviceId = await getDeviceId();
        if (currentDeviceId == null) throw Exception("Could not get device ID.");

        final storedDeviceId = userData['deviceId'];
        if (storedDeviceId != null && storedDeviceId != currentDeviceId) {
          await _showDeviceMismatchDialog();
          await FirebaseAuth.instance.signOut();
        } else {
          if (storedDeviceId == null) {
            await userDocRef.update({'deviceId': currentDeviceId, 'lastLogin': Timestamp.now()});
          } else {
            await userDocRef.update({'lastLogin': Timestamp.now()});
          }
          if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => AppProtector(child: MainNavigation())));
        }
      } else {
        final currentDeviceId = await getDeviceId();
         await userDocRef.set({
          'deviceId': currentDeviceId,
          'createdAt': Timestamp.now(),
          'lastLogin': Timestamp.now(),
          'email': user.email,
          'inactive': 'no', // Set initial state
        }, SetOptions(merge: true));
        if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => AppProtector(child: MainNavigation())));
      }
    } catch (e) {
      if (mounted) setState(() => _hasInternet = false);
    }
  }

  Future<void> _showDeviceMismatchDialog() async {
     return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          icon: Icon(Icons.screen_lock_portrait_rounded, size: 60, color: Colors.red.shade700),
          title: const Text("Account Registered on Another Device", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
          content: const Text("You can only use this account on the first device you logged in from. Please log in from your primary device.", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, height: 1.5)),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(130, 48),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("OK", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.only(bottom: 20.0),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_isAccountBlocked) {
      return const MaterialApp(debugShowCheckedModeBanner: false, home: AccountBlockedScreen());
    }
    if (!_hasInternet) {
      return MaterialApp(debugShowCheckedModeBanner: false, home: NoInternetScreen(onRetry: _performChecks));
    }
    if (_isEmulator) {
      return const MaterialApp(debugShowCheckedModeBanner: false, home: EmulatorBlockedScreen());
    }
    if (_isDeveloperMode) {
      return const MaterialApp(debugShowCheckedModeBanner: false, home: DeveloperModeBlockedScreen());
    }
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

// ======================================
// ======== Login Screen
// ======================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  bool isLoading = false;
  bool _isLogin = true;
  bool _showNoInternet = false;

  Future<void> _showNoSimDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          icon: Icon(Icons.sim_card_alert_outlined, size: 60, color: Colors.red.shade700),
          title: const Text("SIM Card Required", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
          content: const Text("For security reasons, this application requires an active SIM card in your device to continue.", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, height: 1.5)),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(130, 48),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("OK"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.only(bottom: 20.0),
        );
      },
    );
  }

  Future<bool> _checkInternet() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult.contains(ConnectivityResult.mobile) || connectivityResult.contains(ConnectivityResult.wifi);
  }

  Future<void> _authenticate() async {
    if (!mounted) return;

    if (!await _checkInternet()) {
      setState(() => _showNoInternet = true);
      return;
    }

    setState(() {
      isLoading = true;
      _showNoInternet = false;
    });

    final bool isSimValid = await isEgyptianSimPresent();
    if (!isSimValid) {
      if (mounted) await _showNoSimDialog();
      setState(() => isLoading = false);
      return;
    }

    if (!_isLogin) {
      if (nameController.text.trim().isEmpty ||
          emailController.text.trim().isEmpty ||
          passwordController.text.trim().isEmpty ||
          phoneController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill in all fields.")));
        setState(() => isLoading = false);
        return;
      }
    }

    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      } else {
        final phoneQuery = await FirebaseFirestore.instance.collection('users').where('phone', isEqualTo: phoneController.text.trim()).limit(1).get();
        if (phoneQuery.docs.isNotEmpty) {
          throw FirebaseAuthException(code: 'phone-already-in-use');
        }

        final currentDeviceId = await getDeviceId();
        if (currentDeviceId == null) throw Exception("Could not get device ID.");

        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        final userData = {
          'email': emailController.text.trim(),
          'name': nameController.text.trim(),
          'phone': phoneController.text.trim(),
          'createdAt': Timestamp.now(),
          'lastLogin': Timestamp.now(),
          'deviceId': currentDeviceId,
          'inactive': 'no', // Initialize as not inactive
        };

        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set(userData);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "An error occurred. Please try again.";
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        errorMessage = "Invalid email or password.";
      } else if (e.code == 'email-already-in-use') {
        errorMessage = "This email is already registered.";
      } else if (e.code == 'phone-already-in-use') {
        errorMessage = "This phone number is already registered.";
      }
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
    } on SocketException catch (_) {
      if (mounted) setState(() => _showNoInternet = true);
    } on Exception catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("An error occurred: ${e.toString()}")));
    }
    finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!await _checkInternet()) {
      setState(() => _showNoInternet = true);
      return;
    }

    final email = emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter your email.")));
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password reset link sent!")));
    } on FirebaseAuthException catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.message}")));
    }
  }

  void _toggleFormType() {
    setState(() => _isLogin = !_isLogin);
  }

 @override
  Widget build(BuildContext context) {

    if (_showNoInternet) {
      return NoInternetScreen(onRetry: () {
        setState(() {
          _showNoInternet = false;
        });
        _authenticate(); // Retry authentication
      });
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
      hintStyle: TextStyle(color: Colors.grey[500]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue.shade300, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/logo.png', width: 160, height: 160),
                const SizedBox(height: 24),
                Text(
                  _isLogin ? "Sign In" : "Create Account",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : const Color(0xFF333333)),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin ? "Welcome back, you've been missed!" : "Let's get you started on your path.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                ),
                const SizedBox(height: 48),

                if (!_isLogin)
                  TextFormField(
                    controller: nameController,
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                    decoration: inputDecoration.copyWith(
                      hintText: "Enter your name",
                      prefixIcon: Icon(Icons.person_outline, color: Colors.grey[500]),
                    ),
                  ),
                if (!_isLogin) const SizedBox(height: 16),

                TextFormField(
                  controller: emailController,
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                  keyboardType: TextInputType.emailAddress,
                  decoration: inputDecoration.copyWith(
                    hintText: "Enter your email",
                    prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[500]),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: passwordController,
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                  obscureText: true,
                  decoration: inputDecoration.copyWith(
                    hintText: "Enter your password",
                    prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[500]),
                  ),
                ),
                if (_isLogin) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _resetPassword,
                      child: const Text("Forgot Password?", style: TextStyle(color: Colors.blue)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ] else ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: phoneController,
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                    keyboardType: TextInputType.phone,
                    decoration: inputDecoration.copyWith(
                      hintText: "Enter your phone number",
                      prefixIcon: Icon(Icons.phone_outlined, color: Colors.grey[500]),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                if (isLoading)
                  const CircularProgressIndicator()
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _authenticate,
                      child: Text(
                        _isLogin ? "SIGN IN" : "CREATE ACCOUNT",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLogin ? "Don't have an account?" : "Already have an account?",
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                    TextButton(
                      onPressed: _toggleFormType,
                      child: Text(
                        _isLogin ? "Sign Up" : "Sign In",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// ======================================
// ======== Main Navigation
// ======================================
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    CoursesScreen(),
    ProfileScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initFirebaseMessaging();
  }

  Future<void> _initFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      final fcmToken = await messaging.getToken();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && fcmToken != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'fcmToken': fcmToken,
        });
      }
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (mounted && message.notification != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message.notification!.title ?? 'New Message')),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: "Courses"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }
}

// ======================================
// ======== Home Screen
// ======================================
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Doctor's Path Academy"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png',
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 20),
            const Text(
              "Welcome to Doctor's Path Academy 🦷",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================
// ======== Watermark Widget
// ======================================
class DynamicWatermark extends StatefulWidget {
  final String text;
  const DynamicWatermark({super.key, required this.text});

  @override
  State<DynamicWatermark> createState() => _DynamicWatermarkState();
}

class _DynamicWatermarkState extends State<DynamicWatermark> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(MediaQuery.of(context).size.width * _controller.value, MediaQuery.of(context).size.height * 0.3 * (1 - _controller.value)),
            child: Transform.rotate(
              angle: -0.5, // 45 degrees in radians
              child: Text(
                widget.text,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black.withOpacity(0.05),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ======================================
// ======== Courses Screen
// ======================================
class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Our Courses")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const Text("Our Courses")),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('course')
                .where('authorizedUsers', arrayContains: user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text("Something went wrong"));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No courses available for you yet."));
              }

              final courses = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: courses.length,
                itemBuilder: (context, index) {
                  final course = courses[index];
                  final courseData = course.data() as Map<String, dynamic>;
                  final String title = courseData['title'] ?? 'No Title';
                  final String description = courseData['description'] ?? 'No Description';
                  final String thumbnailUrl = courseData['thumbnailUrl'] ?? '';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 20),
                    elevation: 5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(15),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LecturesScreen(
                              courseId: course.id,
                              courseTitle: title,
                            ),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(15),
                              topRight: Radius.circular(15),
                            ),
                            child: thumbnailUrl.isNotEmpty
                                ? Image.network(
                              thumbnailUrl,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, size: 40),
                            )
                                : Container(
                              height: 200,
                              color: Colors.grey[300],
                              child: const Center(child: Icon(Icons.school, size: 50, color: Colors.grey)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  description,
                                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        DynamicWatermark(text: user.email ?? ''),
      ],
    );
  }
}


// ======================================
// ======== Settings Screen
// ======================================
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showAboutUsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("About Us"),
        content: const Text("This application was programmed by Dr. Mohamed\nPhone: 01271438806"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSettingsSectionTitle("Appearance"),
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return _buildSettingsTile(
                    context,
                    icon: Icons.dark_mode_outlined,
                    iconBgColor: Colors.purple,
                    title: "Dark Mode",
                    trailing: Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (value) {
                        themeProvider.toggleTheme();
                      },
                    ),
                    onTap: () {
                      themeProvider.toggleTheme();
                    },
                  );
                },
              ),
              const Divider(height: 32),
              _buildSettingsSectionTitle("Notifications"),
              _buildSettingsTile(context, icon: Icons.notifications_outlined, iconBgColor: Colors.orange, title: "Course Updates", onTap: () {}),
              _buildSettingsTile(context, icon: Icons.calendar_today_outlined, iconBgColor: Colors.blue, title: "Exam Reminders", onTap: () {}),
              const Divider(height: 32),
              _buildSettingsSectionTitle("Language"),
              _buildSettingsTile(context, icon: Icons.language_outlined, iconBgColor: Colors.pink, title: "English", onTap: () {}),
              const Divider(height: 32),
              _buildSettingsSectionTitle("Security"),
              _buildSettingsTile(context, icon: Icons.fingerprint, iconBgColor: Colors.teal, title: "Biometric Login", trailing: Switch(value: false, onChanged: (val){}), onTap: () {}),
              _buildSettingsTile(context, icon: Icons.security_outlined, iconBgColor: Colors.green, title: "Remember Me", trailing: Switch(value: true, onChanged: (val){}), onTap: () {}),
              if (userProvider.isAdmin) ...[
                const Divider(height: 32),
                _buildSettingsSectionTitle("Admin"),
                _buildSettingsTile(
                  context,
                  icon: Icons.dashboard_customize_outlined,
                  iconBgColor: Colors.red,
                  title: "Admin Dashboard",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AdminScreen()),
                    );
                  },
                ),
              ],
              const Divider(height: 32),
              _buildSettingsSectionTitle("About"),
              _buildSettingsTile(context, icon: Icons.info_outline, iconBgColor: Colors.cyan, title: "About Us", onTap: () => _showAboutUsDialog(context)),
              _buildSettingsTile(context, icon: Icons.privacy_tip_outlined, iconBgColor: Colors.indigo, title: "Privacy Policy", onTap: () {}),
              _buildSettingsTile(context, icon: Icons.description_outlined, iconBgColor: Colors.brown, title: "Terms & Conditions", onTap: () {}),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSettingsSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 8.0, top: 16.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey[600],
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap, Widget? trailing, required Color iconBgColor}) {
    return ListTile(
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: iconBgColor.withOpacity(0.15),
        child: Icon(icon, color: iconBgColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}


// ======================================
// ======== Edit Profile Screen
// ======================================
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Fetch user's current name
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance.collection('users').doc(user.uid).get().then((doc) {
        if (doc.exists && doc.data()!.containsKey('name')) {
          setState(() {
            _nameController.text = doc.data()!['name'];
          });
        }
      });
    }
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Name cannot be empty")));
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'name': _nameController.text.trim(),
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated successfully")));
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if(mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Full Name"),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50) // make button wider
                ),
                onPressed: _updateProfile,
                child: const Text("Save Changes"),
              ),
          ],
        ),
      ),
    );
  }
}
