import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai/models/chat_message.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String conversationId;

  FirestoreService({required this.conversationId});

  CollectionReference<Map<String, dynamic>> _messagesRef() =>
      _db.collection('conversations').doc(conversationId).collection('messages');

  /// Load last `limit` messages ordered ascending by createdAt
  Future<List<ChatMessage>> loadChat({int limit = 200}) async {
    final q = _messagesRef().orderBy('createdAt', descending: false).limit(limit);
    final snap = await q.get();
    return snap.docs.map((d) => ChatMessage.fromFirestore(d)).toList();
  }

  /// Save a message (ensures senderId comes from current auth)
  Future<DocumentReference<Map<String, dynamic>>> saveMessage(ChatMessage m) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception('Not signed in');
    }

    final data = {
      'senderId': uid,
      'role': m.role,
      'content': m.content,
      'createdAt': FieldValue.serverTimestamp(),
    };

    return await _messagesRef().add(data);
  }
}