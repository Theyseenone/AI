import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String? id;
  final String senderId;
  final String role; // 'user' | 'assistant' | 'system'
  final String content;
  final DateTime timestamp;

  ChatMessage({
    this.id,
    required this.senderId,
    required this.role,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toMapForSave() {
    return {
      'senderId': senderId,
      'role': role,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory ChatMessage.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final Timestamp? ts = data['createdAt'] as Timestamp?;
    final dt = ts != null ? ts.toDate() : DateTime.now();
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      role: data['role'] ?? 'user',
      content: data['content'] ?? '',
      timestamp: dt,
    );
  }
}
