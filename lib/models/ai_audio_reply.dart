import 'dart:convert';

class AIAudioReply {
  const AIAudioReply({
    required this.success,
    required this.transcription,
    required this.response,
    this.conversationId,
    this.toolsUsed,
    this.conversationHistory,
  });

  final bool success;
  final String transcription;
  final String response;
  final String? conversationId;
  final List<String>? toolsUsed;
  final List<dynamic>? conversationHistory;

  factory AIAudioReply.fromJson(Map<String, dynamic> json) {
    final success = json['success'];
    final data = json['data'];

    if (success is! bool) {
      throw const FormatException('Campo success inválido');
    }

    if (data is! Map<String, dynamic>) {
      throw const FormatException('Campo data inválido');
    }

    final transcription = data['transcription'];
    if (transcription is! String || transcription.trim().isEmpty) {
      throw const FormatException('Transcripción inválida');
    }

    final response = data['response'];
    if (response is! String || response.trim().isEmpty) {
      throw const FormatException('Respuesta inválida');
    }

    final conversationIdValue = data['conversationId'];
    final conversationId =
        conversationIdValue is String && conversationIdValue.isNotEmpty
            ? conversationIdValue
            : null;

    final toolsUsedRaw = data['toolsUsed'];
    final toolsUsed = toolsUsedRaw is List
        ? toolsUsedRaw.whereType<String>().toList(growable: false)
        : null;

    final conversationHistoryRaw = data['conversationHistory'];
    final conversationHistory =
        conversationHistoryRaw is List ? conversationHistoryRaw : null;

    return AIAudioReply(
      success: success,
      transcription: transcription,
      response: response,
      conversationId: conversationId,
      toolsUsed: toolsUsed,
      conversationHistory: conversationHistory,
    );
  }

  String toJsonString() {
    return jsonEncode({
      'success': success,
      'data': {
        'transcription': transcription,
        'response': response,
        'conversationId': conversationId,
        'toolsUsed': toolsUsed,
        'conversationHistory': conversationHistory,
      },
    });
  }
}
