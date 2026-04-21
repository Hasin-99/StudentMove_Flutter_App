import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/notification_service.dart';
import '../core/prefs_keys.dart';

class AuthProvider with ChangeNotifier {
  AuthProvider() {
    _authStateSub = FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) {
        _isAuthenticated = false;
        _userEmail = null;
        _userName = null;
        _userPhone = null;
        _studentId = null;
        _institutionType = null;
        _institutionName = null;
        _department = null;
        _address = null;
        _dateOfBirth = null;
      } else {
        try {
          await _hydrateFromFirebaseUser(user);
        } catch (e) {
          _isAuthenticated = false;
          _lastError = 'Session refresh failed: $e';
        }
      }
      notifyListeners();
    });
  }

  static final RegExp emailPattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late final StreamSubscription<User?> _authStateSub;

  static bool isValidEmail(String email) =>
      emailPattern.hasMatch(email.trim().toLowerCase());

  bool _isAuthenticated = false;
  String? _lastError;
  String? _userEmail;
  String? _userName;
  String? _userPhone;
  String? _studentId;
  String? _institutionType;
  String? _institutionName;
  String? _department;
  String? _address;
  String? _dateOfBirth;
  String? _profileImagePath;

  bool get isAuthenticated => _isAuthenticated;
  String? get lastError => _lastError;
  String? get userId => _auth.currentUser?.uid;
  String? get userEmail => _userEmail;
  String? get userName => _userName;
  String? get userPhone => _userPhone;
  String? get studentId => _studentId;
  String? get institutionType => _institutionType;
  String? get institutionName => _institutionName;
  String? get department => _department;
  String? get university => _institutionName;
  String? get address => _address;
  String? get dateOfBirth => _dateOfBirth;
  String? get profileImagePath => _profileImagePath;

  static String displayNameFromEmail(String email) {
    final local = email.split('@').first;
    if (local.isEmpty) return 'Traveler';
    return local
        .replaceAll(RegExp(r'[._-]+'), ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.length > 1 ? w.substring(1) : ''}')
        .join(' ');
  }

  Future<void> signIn(String email, String password) async {
    final trimmed = email.trim().toLowerCase();
    if (!emailPattern.hasMatch(trimmed) || password.length < 8) {
      _lastError = 'Invalid email or weak password';
      notifyListeners();
      return;
    }

    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: trimmed,
        password: password,
      );
      _isAuthenticated = true;
      _lastError = null;
      await _hydrateFromFirebaseUser(cred.user);
    } catch (e) {
      _lastError = 'Sign-in failed: $e';
      notifyListeners();
      return;
    }

    notifyListeners();
  }

  Future<void> signUp(
    String email,
    String password,
    String name, {
    String? phone,
    String? studentId,
    String? university,
  }) async {
    final trimmed = email.trim().toLowerCase();
    if (!emailPattern.hasMatch(trimmed) || password.length < 8) {
      _lastError = 'Invalid email or weak password';
      return;
    }

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: trimmed,
        password: password,
      );
      final uid = cred.user?.uid;
      if (uid == null) {
        _lastError = 'Could not create account';
        notifyListeners();
        return;
      }

      final safeName = name.trim().isEmpty ? displayNameFromEmail(trimmed) : name.trim();
      final phoneTrim = phone?.trim();
      final sid = studentId?.trim();
      final uni = university?.trim();
      await cred.user?.updateDisplayName(safeName);
      await _db.collection('users').doc(uid).set({
        'fullName': safeName,
        'email': trimmed,
        'phone': (phoneTrim == null || phoneTrim.isEmpty) ? null : phoneTrim,
        'studentId': (sid == null || sid.isEmpty) ? null : sid,
        'institutionType': (uni == null || uni.isEmpty) ? null : 'university',
        'institutionName': (uni == null || uni.isEmpty) ? null : uni,
        'department': null,
        'role': 'student',
        'status': 'active',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _db.collection('userPreferences').doc(uid).set({
        'savedRoutes': <String>[],
        'locale': 'en',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _isAuthenticated = true;
      _lastError = null;
      await _hydrateFromFirebaseUser(cred.user);
    } catch (e) {
      _lastError = 'Sign-up failed: $e';
      notifyListeners();
      return;
    }

    notifyListeners();
  }

  Future<bool> resetPasswordWithToken({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    final trimmed = email.trim().toLowerCase();
    if (!emailPattern.hasMatch(trimmed)) {
      _lastError = 'Invalid email';
      notifyListeners();
      return false;
    }

    try {
      final code = token.trim();
      if (code.isEmpty) {
        // Backward-compatible path used by forgot password flow.
        await _auth.sendPasswordResetEmail(email: trimmed);
      } else {
        if (newPassword.trim().length < 8) {
          _lastError = 'Password must be at least 8 characters';
          notifyListeners();
          return false;
        }
        await _auth.confirmPasswordReset(code: code, newPassword: newPassword.trim());
      }
      _lastError = null;
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = token.trim().isEmpty
          ? 'Reset email failed: $e'
          : 'Password reset failed: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> updateProfile({
    required String fullName,
    String? phone,
    String? institutionType,
    String? institutionName,
    String? department,
    String? address,
    String? dateOfBirth,
    String? profileImagePath,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final name = fullName.trim();
    if (name.isEmpty) return;
    try {
      await user.updateDisplayName(name);
      await _db.collection('users').doc(user.uid).set({
        'fullName': name,
        'phone': (phone == null || phone.trim().isEmpty) ? null : phone.trim(),
        'institutionType': (institutionType == null || institutionType.trim().isEmpty)
            ? null
            : institutionType.trim().toLowerCase(),
        'institutionName': (institutionName == null || institutionName.trim().isEmpty)
            ? null
            : institutionName.trim(),
        'department': (department == null || department.trim().isEmpty)
            ? null
            : department.trim(),
        'address': (address == null || address.trim().isEmpty) ? null : address.trim(),
        'dateOfBirth': (dateOfBirth == null || dateOfBirth.trim().isEmpty)
            ? null
            : dateOfBirth.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      final prefs = await SharedPreferences.getInstance();
      if (profileImagePath != null) {
        await prefs.setString('profile_image_path', profileImagePath);
      }
      await _hydrateFromFirebaseUser(user);
      notifyListeners();
    } catch (e) {
      _lastError = 'Could not update profile: $e';
      notifyListeners();
    }
  }

  Future<void> checkAuthStatus() async {
    final user = _auth.currentUser;
    if (user == null) {
      _isAuthenticated = false;
      _userEmail = null;
      _userName = null;
      _userPhone = null;
      _studentId = null;
      _institutionType = null;
      _institutionName = null;
      _department = null;
      _address = null;
      _dateOfBirth = null;
    } else {
      try {
        await _hydrateFromFirebaseUser(user);
      } catch (e) {
        _isAuthenticated = false;
        _lastError = 'Session check failed: $e';
      }
    }
    notifyListeners();
  }

  Future<void> signOut() async {
    String? keepLocale;
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
      keepLocale = prefs.getString(PrefsKeys.locale);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Sign-out prefs load failed: $e');
      }
    }

    try {
      await _auth.signOut();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Firebase sign-out failed: $e');
      }
      _lastError = 'Sign-out partially failed. Local session was cleared.';
    }
    _isAuthenticated = false;
    _userEmail = null;
    _userName = null;
    _userPhone = null;
    _studentId = null;
    _institutionType = null;
    _institutionName = null;
    _department = null;
    _address = null;
    _dateOfBirth = null;
    _profileImagePath = null;
    if (prefs != null) {
      try {
        await prefs.remove('sub_plan');
        await prefs.remove('sub_until_ms');
        await prefs.remove('saved_routes');
        await prefs.remove('profile_image_path');
        if (keepLocale != null) {
          await prefs.setString(PrefsKeys.locale, keepLocale);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Local cleanup during sign-out failed: $e');
        }
        _lastError ??= 'Signed out, but local cleanup had an issue.';
      }
    }

    notifyListeners();
  }

  Future<void> _hydrateFromFirebaseUser(User? user) async {
    if (user == null) return;
    final email = (user.email ?? '').trim().toLowerCase();
    _isAuthenticated = true;
    _userEmail = email.isEmpty ? null : email;

    var data = (await _db.collection('users').doc(user.uid).get()).data() ?? <String, dynamic>{};
    if (await _backfillUserDocIfNeeded(user, data)) {
      data = (await _db.collection('users').doc(user.uid).get()).data() ?? <String, dynamic>{};
    }
    final profileName = '${data['fullName'] ?? ''}'.trim();
    final fromAuth = user.displayName?.trim() ?? '';
    _userName = profileName.isNotEmpty
        ? profileName
        : (fromAuth.isNotEmpty
            ? fromAuth
            : (_userEmail == null ? 'Traveler' : displayNameFromEmail(_userEmail!)));
    final phoneRaw = data['phone'];
    final phoneStr = phoneRaw == null ? '' : '$phoneRaw'.trim();
    _userPhone = phoneStr.isEmpty ? null : phoneStr;
    final sid = '${data['studentId'] ?? ''}'.trim();
    final dep = '${data['department'] ?? ''}'.trim();
    final institutionTypeRaw = '${data['institutionType'] ?? ''}'.trim().toLowerCase();
    final institutionNameRaw = '${data['institutionName'] ?? ''}'.trim();
    final addressRaw = '${data['address'] ?? ''}'.trim();
    final dobRaw = '${data['dateOfBirth'] ?? ''}'.trim();
    _studentId = sid.isEmpty ? null : sid;
    _department = dep.isEmpty ? null : dep;
    _institutionType = institutionTypeRaw.isEmpty ? null : institutionTypeRaw;
    _institutionName = institutionNameRaw.isEmpty ? null : institutionNameRaw;
    _address = addressRaw.isEmpty ? null : addressRaw;
    _dateOfBirth = dobRaw.isEmpty ? null : dobRaw;
    try {
      final prefs = await SharedPreferences.getInstance();
      final imagePath = prefs.getString('profile_image_path');
      _profileImagePath = (imagePath == null || imagePath.trim().isEmpty)
          ? null
          : imagePath.trim();
    } catch (_) {
      _profileImagePath = null;
    }
    _lastError = null;

    await _syncFcmToken(user.uid);
    await _reverseSyncPreferredRoutes(user.uid);
  }

  /// Syncs Firestore `users/{uid}` when admin created Auth user + partial Firestore row
  /// (e.g. missing fullName) so the admin panel and app agree on profile fields.
  Future<bool> _backfillUserDocIfNeeded(User user, Map<String, dynamic> data) async {
    final patches = <String, dynamic>{};
    final fullName = '${data['fullName'] ?? ''}'.trim();
    final dn = user.displayName?.trim() ?? '';
    if (fullName.isEmpty && dn.isNotEmpty) {
      patches['fullName'] = dn;
    }
    final email = (user.email ?? '').trim().toLowerCase();
    final storedEmail = '${data['email'] ?? ''}'.trim().toLowerCase();
    if (email.isNotEmpty && storedEmail.isEmpty) {
      patches['email'] = email;
    }
    if (data['isActive'] == null && data['status'] == null) {
      patches['isActive'] = true;
    }
    if (data['address'] == null) {
      patches['address'] = null;
    }
    if (data['dateOfBirth'] == null) {
      patches['dateOfBirth'] = null;
    }
    if (patches.isEmpty) return false;
    patches['updatedAt'] = FieldValue.serverTimestamp();
    await _db.collection('users').doc(user.uid).set(patches, SetOptions(merge: true));
    return true;
  }

  Future<void> _reverseSyncPreferredRoutes(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final localRoutes = prefs.getStringList('saved_routes') ?? <String>[];

    try {
      final prefDoc = await _db.collection('userPreferences').doc(uid).get();
      final serverRaw = prefDoc.data()?['savedRoutes'];
      final serverRoutes = serverRaw is List
          ? serverRaw.map((e) => '$e'.trim()).where((e) => e.isNotEmpty).toList()
          : <String>[];

      final merged = <String>[];
      for (final r in [...localRoutes, ...serverRoutes]) {
        if (!merged.contains(r)) merged.add(r);
      }
      await prefs.setStringList('saved_routes', merged);
      await _db.collection('userPreferences').doc(uid).set({
        'savedRoutes': merged,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // silent fail to avoid blocking login
    }
  }

  Future<void> _syncFcmToken(String uid) async {
    final token = NotificationService.lastToken;
    if (token == null || token.isEmpty) return;
    try {
      await _db.collection('users').doc(uid).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FCM token sync failed: $e');
      }
    }
  }

  @override
  void dispose() {
    _authStateSub.cancel();
    super.dispose();
  }
}
