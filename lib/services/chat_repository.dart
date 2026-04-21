import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../data/chat_message.dart';

class ChatRepository extends ChangeNotifier {
  List<ChatMessage> _messages = const [];
  bool _loading = false;
  String? _lastError;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  List<ChatMessage> get messages => _messages;
  bool get loading => _loading;
  String? get lastError => _lastError;

  Future<void> refresh(String email) async {
    if (email.trim().isEmpty) return;
    _loading = true;
    _lastError = null;
    notifyListeners();

    try {
      final roomId = await _resolveRoomId(email);
      _sub ??= FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(roomId)
          .collection('messages')
          .orderBy('createdAt', descending: false)
          .snapshots()
          .listen((snap) {
        _messages = snap.docs.map((doc) {
          final d = doc.data();
          final createdAt = d['createdAt'];
          return ChatMessage.fromJson({
            'id': doc.id,
            'message': d['text'],
            'sender_role': d['senderRole'],
            'created_at': createdAt is Timestamp
                ? createdAt.toDate().toIso8601String()
                : DateTime.now().toIso8601String(),
          });
        }).toList();
        _loading = false;
        _lastError = null;
        notifyListeners();
      }, onError: (e) {
        _lastError = 'Could not sync with admin chat: $e';
        _loading = false;
        notifyListeners();
      });
    } catch (e) {
      _lastError = 'Could not sync with admin chat: $e';
    }

    _loading = false;
    notifyListeners();
  }

  Future<bool> sendMessage({
    required String email,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (email.trim().isEmpty || trimmed.isEmpty) return false;

    final local = ChatMessage(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      text: trimmed,
      senderRole: 'user',
      createdAt: DateTime.now(),
    );
    _messages = [..._messages, local];
    notifyListeners();

    try {
      final roomId = await _resolveRoomId(email);
      await FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(roomId)
          .set({'ownerEmail': email.trim().toLowerCase()}, SetOptions(merge: true));
      await FirebaseFirestore.instance.collection('chatRooms').doc(roomId).collection('messages').add({
        'text': trimmed,
        'senderRole': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _lastError = 'Message sent locally, server not reachable: $e';
      notifyListeners();
      return false;
    }
  }

  Future<String> _resolveRoomId(String email) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.uid.trim().isNotEmpty) {
      return currentUser.uid;
    }

    final normalized = email.trim().toLowerCase();
    final users = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: normalized)
        .limit(1)
        .get();
    if (users.docs.isNotEmpty) {
      return users.docs.first.id;
    }
    return normalized.replaceAll(RegExp(r'[^a-z0-9]'), '_');
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
