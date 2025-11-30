class Usage {
  const Usage({
    this.promptTokens,
    this.completionTokens,
    this.totalTokens,
    this.promptEvalCount,
    this.evalCount,
    this.promptEvalDuration,
    this.evalDuration,
    this.loadDuration,
    this.totalDuration,
  });

  final int? promptTokens;
  final int? completionTokens;
  final int? totalTokens;
  final int? promptEvalCount;
  final int? evalCount;
  final int? promptEvalDuration;
  final int? evalDuration;
  final int? loadDuration;
  final int? totalDuration;

  factory Usage.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const Usage();
    }

    return Usage(
      promptTokens: _parseInt(json['prompt_tokens'] ?? json['promptTokens']),
      completionTokens:
          _parseInt(json['completion_tokens'] ?? json['completionTokens']),
      totalTokens: _parseInt(json['total_tokens'] ?? json['totalTokens']),
      promptEvalCount:
          _parseInt(json['prompt_eval_count'] ?? json['promptEvalCount']),
      evalCount: _parseInt(json['eval_count'] ?? json['evalCount']),
      promptEvalDuration: _parseInt(
        json['prompt_eval_duration'] ?? json['promptEvalDuration'],
      ),
      evalDuration: _parseInt(json['eval_duration'] ?? json['evalDuration']),
      loadDuration: _parseInt(json['load_duration'] ?? json['loadDuration']),
      totalDuration: _parseInt(json['total_duration'] ?? json['totalDuration']),
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'prompt_tokens': promptTokens,
      'completion_tokens': completionTokens,
      'total_tokens': totalTokens,
      'prompt_eval_count': promptEvalCount,
      'eval_count': evalCount,
      'prompt_eval_duration': promptEvalDuration,
      'eval_duration': evalDuration,
      'load_duration': loadDuration,
      'total_duration': totalDuration,
    };
    data.removeWhere((_, value) => value == null);
    return data;
  }
}

int? _parseInt(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  return int.tryParse(value.toString());
}