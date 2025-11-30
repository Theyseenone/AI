import 'package:ai/models/choices.dart';
import 'package:ai/models/usage.dart';

class ResponseModel {
  const ResponseModel({
    this.id,
    this.object,
    this.created,
    this.model,
    this.choices = const [],
    this.usage,
  });

  final String? id;
  final String? object;
  final int? created;
  final String? model;
  final List<Choices> choices;
  final Usage? usage;

  factory ResponseModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ResponseModel();
    }

    final baseId = json['id']?.toString();
    final baseObject = json['object']?.toString();
    final createdValue = json['created'] ?? json['created_at'];
    final created = createdValue is int
        ? createdValue
        : int.tryParse(createdValue?.toString() ?? '');
    final baseModel = json['model']?.toString();
    final usage = Usage.fromJson(_mergeUsage(json));

    final rawChoices = json['choices'];
    if (rawChoices is List && rawChoices.isNotEmpty) {
      return ResponseModel(
        id: baseId,
        object: baseObject,
        created: created,
        model: baseModel,
        choices: rawChoices
            .map(
              (choice) =>
                  Choices.fromJson(choice as Map<String, dynamic>? ?? const {}),
            )
            .toList(),
        usage: usage,
      );
    }

    final message = json['message'];
    if (message is Map<String, dynamic>) {
      return ResponseModel(
        id: baseId,
        object: baseObject,
        created: created,
        model: baseModel,
        choices: [
          Choices(
            content: message['content']?.toString(),
            index: 0,
            role: message['role']?.toString(),
          ),
        ],
        usage: usage,
      );
    }

    final responseText = json['response']?.toString();
    if (responseText != null && responseText.isNotEmpty) {
      return ResponseModel(
        id: baseId,
        object: baseObject,
        created: created,
        model: baseModel,
        choices: [
          Choices(
            content: responseText,
            index: 0,
            role: json['role']?.toString() ?? 'assistant',
            finishReason: json['done'] == true ? 'stop' : null,
          ),
        ],
        usage: usage,
      );
    }

    return ResponseModel(
      id: baseId,
      object: baseObject,
      created: created,
      model: baseModel,
      usage: usage,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'object': object,
    'created': created,
    'model': model,
    'choices': choices.map((choice) => choice.toJson()).toList(),
    'usage': usage?.toJson(),
  };
}

Map<String, dynamic>? _mergeUsage(Map<String, dynamic> json) {
  final usageMap = <String, dynamic>{};
  final nestedUsage = json['usage'];
  if (nestedUsage is Map<String, dynamic>) {
    usageMap.addAll(nestedUsage);
  }

  void addIfPresent(String key) {
    final value = json[key];
    if (value != null) {
      usageMap[key] = value;
    }
  }

  const ollamaKeys = [
    'prompt_eval_count',
    'eval_count',
    'total_duration',
    'load_duration',
    'prompt_eval_duration',
    'eval_duration',
  ];
  for (final key in ollamaKeys) {
    addIfPresent(key);
  }

  return usageMap.isEmpty ? null : usageMap;
}