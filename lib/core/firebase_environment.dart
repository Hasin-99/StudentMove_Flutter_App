class FirebaseEnvironment {
  static const flavor = String.fromEnvironment(
    'FIREBASE_FLAVOR',
    defaultValue: 'dev',
  );

  static const useEmulator = bool.fromEnvironment(
    'USE_FIREBASE_EMULATOR',
    defaultValue: false,
  );
}
