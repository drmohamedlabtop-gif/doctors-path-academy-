import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// =============================================
// ======== USER MODEL
// =============================================
class UserModel {
  final String uid;
  final String? email;
  final String role;
  final Map<String, dynamic> permissions;
  final bool accountEnabled;

  UserModel({
    required this.uid,
    this.email,
    this.role = 'student',
    this.permissions = const {},
    this.accountEnabled = true,
  });

  bool hasPermission(String key) {
    if (role == 'superAdmin') return true;
    return permissions[key] as bool? ?? false;
  }

  List<String> get accessibleCourseIds {
    if (role == 'superAdmin') return [];
    return List<String>.from(permissions['accessibleCourseIds'] ?? []);
  }
}

// =============================================
// ======== USER PROVIDER (with Caching)
// =============================================
class UserProvider with ChangeNotifier {
  UserModel? _user;
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? get user => _user;

  bool get isSuperAdmin => _user?.role == 'superAdmin';
  bool get isSubAdmin => _user?.role == 'subAdmin';
  bool get isAdmin => isSuperAdmin || isSubAdmin;

  bool hasPermission(String key) => _user?.hasPermission(key) ?? false;
  List<String> get accessibleCourseIds => _user?.accessibleCourseIds ?? [];

  UserProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _user = null;
      _userSubscription?.cancel();
      notifyListeners();
    } else {
      // Cancel any previous subscription
      await _userSubscription?.cancel();
      
      final userDocRef = _firestore.collection('users').doc(firebaseUser.uid);
      
      // Listen for real-time updates
      _userSubscription = userDocRef.snapshots().listen((snapshot) {
        if (snapshot.exists) {
          _processUserData(firebaseUser, snapshot.data()!);
        } else {
          // Handle case where user exists in Auth but not Firestore
          _user = UserModel(uid: firebaseUser.uid, email: firebaseUser.email, role: 'student');
        }
        notifyListeners();
      }, onError: (error) {
        print("Error in user subscription: $error");
        // On error, default to a basic user model to prevent app crash
        _user = UserModel(uid: firebaseUser.uid, email: firebaseUser.email, role: 'student');
        notifyListeners();
      });
    }
  }

  void _processUserData(User firebaseUser, Map<String, dynamic> data) {
    if (data.containsKey('accountEnabled') && data['accountEnabled'] == false) {
      _user = null;
      _auth.signOut();
      return;
    }
    
    String userRole = 'student';
    if (data.containsKey('role')) {
      userRole = data['role'];
    } else if (data['isAdmin'] == true) {
      userRole = 'superAdmin';
    }

    _user = UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email,
      role: userRole,
      permissions: data['permissions'] ?? {},
      accountEnabled: data['accountEnabled'] ?? true,
    );
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  void clearUser() {
    _user = null;
    _userSubscription?.cancel();
    notifyListeners();
  }
}
