import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  image,
  video,
  audio,
  file,
  location,
  sticker,
  gif,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String chatId;
  final String? text;
  final MessageType type;
  final MessageStatus status;
  final DateTime timestamp;
  final bool isDeleted;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final Map<String, dynamic>? metadata;
  final String? replyToMessageId;
  final List<String>? reactions;
  final bool isEdited;
  final DateTime? editedAt;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.chatId,
    this.text,
    this.type = MessageType.text,
    this.status = MessageStatus.sending,
    required this.timestamp,
    this.isDeleted = false,
    this.mediaUrl,
    this.thumbnailUrl,
    this.metadata,
    this.replyToMessageId,
    this.reactions,
    this.isEdited = false,
    this.editedAt,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      chatId: data['chatId'] ?? '',
      text: data['text'],
      type: MessageType.values[data['type'] ?? 0],
      status: MessageStatus.values[data['status'] ?? 1],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isDeleted: data['isDeleted'] ?? false,
      mediaUrl: data['mediaUrl'],
      thumbnailUrl: data['thumbnailUrl'],
      metadata: data['metadata'],
      replyToMessageId: data['replyToMessageId'],
      reactions: data['reactions'] != null 
          ? List<String>.from(data['reactions']) 
          : null,
      isEdited: data['isEdited'] ?? false,
      editedAt: data['editedAt'] != null 
          ? (data['editedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'chatId': chatId,
      'text': text,
      'type': type.index,
      'status': status.index,
      'timestamp': Timestamp.fromDate(timestamp),
      'isDeleted': isDeleted,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'metadata': metadata,
      'replyToMessageId': replyToMessageId,
      'reactions': reactions,
      'isEdited': isEdited,
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
    };
  }

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? chatId,
    String? text,
    MessageType? type,
    MessageStatus? status,
    DateTime? timestamp,
    bool? isDeleted,
    String? mediaUrl,
    String? thumbnailUrl,
    Map<String, dynamic>? metadata,
    String? replyToMessageId,
    List<String>? reactions,
    bool? isEdited,
    DateTime? editedAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      chatId: chatId ?? this.chatId,
      text: text ?? this.text,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      isDeleted: isDeleted ?? this.isDeleted,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      metadata: metadata ?? this.metadata,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      reactions: reactions ?? this.reactions,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
    );
  }
}