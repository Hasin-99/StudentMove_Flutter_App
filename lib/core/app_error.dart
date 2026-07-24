import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Normalized app error with a user-safe message.
class AppException implements Exception {
  const AppException(
    this.message, {
    this.code,
    this.cause,
    this.retriable = true,
  });

  final String message;
  final String? code;
  final Object? cause;
  final bool retriable;

  @override
  String toString() => 'AppException($code): $message';
}

/// Maps platform/Firebase/network failures to friendly copy.
abstract final class ErrorMapper {
  static AppException from(Object error, [StackTrace? stack]) {
    if (error is AppException) return error;

    if (error is FirebaseAuthException) {
      return AppException(
        _authMessage(error.code),
        code: error.code,
        cause: error,
        retriable: error.code == 'network-request-failed',
      );
    }

    if (error is FirebaseException) {
      final code = error.code;
      if (code == 'permission-denied') {
        return AppException(
          'You do not have permission for this action. Sign in again or contact support.',
          code: code,
          cause: error,
          retriable: false,
        );
      }
      if (code == 'unavailable' || code == 'deadline-exceeded') {
        return AppException(
          'Service is temporarily unavailable. Check your connection and retry.',
          code: code,
          cause: error,
        );
      }
      if (code == 'not-found') {
        return AppException(
          'Requested data was not found.',
          code: code,
          cause: error,
          retriable: false,
        );
      }
      return AppException(
        error.message?.trim().isNotEmpty == true
            ? error.message!.trim()
            : 'Something went wrong with the cloud service.',
        code: code,
        cause: error,
      );
    }

    if (error is TimeoutException) {
      return AppException(
        'Request timed out. Please try again.',
        code: 'timeout',
        cause: error,
      );
    }

    final raw = error.toString();
    if (raw.contains('SocketException') ||
        raw.contains('NetworkException') ||
        raw.contains('Failed host lookup') ||
        raw.contains('ClientException')) {
      return AppException(
        'No internet connection. You can keep browsing offline data.',
        code: 'network',
        cause: error,
      );
    }

    if (kDebugMode) {
      debugPrint('Unmapped error: $error');
      if (stack != null) debugPrintStack(stackTrace: stack);
    }

    return AppException(
      'Something went wrong. Please try again.',
      code: 'unknown',
      cause: error,
    );
  }

  static String _authMessage(String code) {
    return switch (code) {
      'invalid-email' => 'Enter a valid email address.',
      'user-disabled' => 'This account has been disabled.',
      'user-not-found' => 'No account found for that email.',
      'wrong-password' => 'Incorrect password. Try again or reset it.',
      'invalid-credential' => 'Email or password is incorrect.',
      'email-already-in-use' => 'An account already exists for that email.',
      'weak-password' => 'Choose a stronger password (8+ characters).',
      'too-many-requests' => 'Too many attempts. Wait a moment and retry.',
      'network-request-failed' => 'Network error. Check your connection.',
      'requires-recent-login' => 'Please sign in again to continue.',
      _ => 'Authentication failed. Please try again.',
    };
  }
}

/// Runs an async action and returns either a value or a mapped [AppException].
Future<T?> guardAsync<T>(
  Future<T> Function() action, {
  void Function(AppException error)? onError,
  bool rethrowFatal = false,
}) async {
  try {
    return await action();
  } catch (e, st) {
    final mapped = ErrorMapper.from(e, st);
    onError?.call(mapped);
    if (rethrowFatal && !mapped.retriable) {
      throw mapped;
    }
    return null;
  }
}

/// Shows a floating snackbar for mapped errors.
void showAppError(
  BuildContext context,
  Object error, {
  String? fallback,
}) {
  final mapped = error is AppException ? error : ErrorMapper.from(error);
  final messenger = ScaffoldMessenger.maybeOf(context);
  messenger?.showSnackBar(
    SnackBar(
      content: Text(fallback ?? mapped.message),
      behavior: SnackBarBehavior.floating,
      action: mapped.retriable
          ? SnackBarAction(
              label: 'OK',
              onPressed: () {},
            )
          : null,
    ),
  );
}

/// Installs global Flutter/platform error hooks.
void installGlobalErrorHandlers({
  GlobalKey<ScaffoldMessengerState>? messengerKey,
}) {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      debugPrint('FlutterError: ${details.exceptionAsString()}');
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    final mapped = ErrorMapper.from(error, stack);
    if (kDebugMode) {
      debugPrint('Uncaught: $mapped');
      debugPrintStack(stackTrace: stack);
    }
    messengerKey?.currentState?.showSnackBar(
      SnackBar(
        content: Text(mapped.message),
        behavior: SnackBarBehavior.floating,
      ),
    );
    // Keep app alive for non-fatal failures.
    return true;
  };
}
