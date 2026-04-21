import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options_dev.dart';
import '../firebase_options_prod.dart';
import 'firebase_environment.dart';

class FirebaseBootstrap {
  static Future<void> initialize() async {
    final options = FirebaseEnvironment.flavor == 'prod'
        ? DefaultFirebaseOptionsProd.currentPlatform
        : DefaultFirebaseOptionsDev.currentPlatform;

    await Firebase.initializeApp(options: options);
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
    );

    // macOS debug can hit stale local Firestore/CoreData store incompatibilities.
    // Disable local persistence in debug to avoid startup hangs/crashes.
    if (!kIsWeb && kDebugMode && defaultTargetPlatform == TargetPlatform.macOS) {
      try {
        // Clear any stale persisted cache from previous runs/configs.
        await FirebaseFirestore.instance.clearPersistence();
      } catch (_) {
        // Ignore if Firestore was already initialized in this process.
      }
      FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: false);
    }

    if (FirebaseEnvironment.useEmulator) {
      await FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
      FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);
      FirebaseFunctions.instance.useFunctionsEmulator('127.0.0.1', 5001);
    }
  }
}
