class Choices {
  const Choices({this.content, this.index, this.role, this.finishReason});

  final String? content;
  final int? index;
  final String? role;
  final String? finishReason;

  factory Choices.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const Choices();
    }

    final message = json['message'] as Map<String, dynamic>?;
    final directContent = json['content'] ?? json['response'];

    final indexValue = json['index'];
    final index =
        indexValue is int ? indexValue : int.tryParse(indexValue?.toString() ?? '');

    return Choices(
      content: (message?['content'] ?? directContent)?.toString(),
      index: index,
      role: (message?['role'] ?? json['role'])?.toString(),
      finishReason: (json['finish_reason'] ?? json['finishReason'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'content': content,
    'index': index,
    'role': role,
    'finish_reason': finishReason,
  };
}