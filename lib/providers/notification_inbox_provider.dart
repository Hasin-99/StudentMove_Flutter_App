import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../core/notification_service.dart';

class InboxNotification {
  const InboxNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
  });

  final String id;
  final String title;
  final String body;
  final DateTime receivedAt;
}

class NotificationInboxProvider extends ChangeNotifier {
  NotificationInboxProvider() {
    _sub = NotificationService.foregroundMessages.listen(_onMessage);
  }

  final List<InboxNotification> _items = <InboxNotification>[];
  StreamSubscription<RemoteMessage>? _sub;

  List<InboxNotification> get items => List.unmodifiable(_items);

  void _onMessage(RemoteMessage message) {
    final now = DateTime.now();
    final title = message.notification?.title?.trim();
    final body = message.notification?.body?.trim();
    final fallbackTitle = message.data['title']?.toString().trim();
    final fallbackBody = message.data['body']?.toString().trim();

    final item = InboxNotification(
      id: message.messageId ?? 'local-${now.microsecondsSinceEpoch}',
      title: (title != null && title.isNotEmpty)
          ? title
          : ((fallbackTitle != null && fallbackTitle.isNotEmpty)
                ? fallbackTitle
                : 'Notification'),
      body: (body != null && body.isNotEmpty)
          ? body
          : ((fallbackBody != null && fallbackBody.isNotEmpty)
                ? fallbackBody
                : 'New update received.'),
      receivedAt: now,
    );

    _items.insert(0, item);
    if (_items.length > 100) {
      _items.removeRange(100, _items.length);
    }
    notifyListeners();
  }

  void clearAll() {
    _items.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _sub = null;
    super.dispose();
  }
}
