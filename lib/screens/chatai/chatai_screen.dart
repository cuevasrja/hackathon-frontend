import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import '../auth/login.dart'; // Para las constantes de color
import 'package:hackathon_frontend/models/ai_audio_reply.dart';
import 'package:hackathon_frontend/services/ai_chat_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:permission_handler/permission_handler.dart';

// --- Modelo de Datos para un Mensaje del Chat ---
class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

// --- Pantalla del Chat con IA ---
class AIPlannerScreen extends StatefulWidget {
  const AIPlannerScreen({super.key});

  @override
  State<AIPlannerScreen> createState() => _AIPlannerScreenState();
}

class _AIPlannerScreenState extends State<AIPlannerScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  final AIChatService _aiChatService = const AIChatService();
  String? _conversationId;
  late final RecorderController _recorderController;
  late final AudioRecorder _audioRecorder;
  bool _isRecordingAudio = false;
  String? _currentRecordingPath;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _audioRecorder = AudioRecorder();
    } else {
      _recorderController = RecorderController()
        ..androidEncoder = AndroidEncoder.aac
        ..androidOutputFormat = AndroidOutputFormat.mpeg4
        ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
        ..sampleRate = 44100
        ..bitRate = 128000;
    }
    // Mensaje de bienvenida de la IA al abrir el chat
    _messages.add(
      ChatMessage(
        text:
            "¡Hola! Soy tu asistente de planes. Dime qué te provoca hacer en Caracas y te daré ideas. Por ejemplo: 'un plan barato para esta noche' o 'dónde comer arepas buenas en Chacao'.",
        isUser: false,
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    if (kIsWeb) {
      _audioRecorder.dispose();
    } else {
      _recorderController.dispose();
    }
    super.dispose();
  }

  // --- Lógica para enviar un mensaje ---
  void _sendMessage() {
    if (_isLoading) {
      return;
    }

    final text = _textController.text.trim();
    if (text.isEmpty) {
      return;
    }

    _textController.clear();
    _handleUserMessage(text);
  }

  // --- Simulación de la respuesta de la IA ---
  Future<void> _getAIResponse(String userMessage) async {
    try {
      final reply = await _aiChatService.sendMessage(
        prompt: userMessage,
        conversationId: _conversationId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _conversationId = reply.conversationId ?? _conversationId;
        _messages.add(ChatMessage(text: reply.message.trim(), isUser: false));
      });
    } on AIChatException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _messages.add(ChatMessage(text: e.message, isUser: false));
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.redAccent),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      const fallback = 'Ocurrió un error al obtener la respuesta de la IA.';
      setState(() {
        _messages.add(ChatMessage(text: fallback, isUser: false));
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo obtener la respuesta de la IA.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  Future<String> _createRecordingPath() async {
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final separator = Platform.pathSeparator;
    final fileName = 'plania_voice_$timestamp.m4a';
    return '${directory.path}$separator$fileName';
  }

  Future<bool> _ensureMicrophonePermission() async {
    if (kIsWeb) {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Se requieren permisos de micrófono para grabar.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return hasPermission;
    }
    PermissionStatus status = await Permission.microphone.status;
    if (status.isPermanentlyDenied) {
      if (!mounted) {
        return false;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Activa el permiso de micrófono en la configuración para grabar notas de voz.',
          ),
          action: SnackBarAction(
            label: 'Abrir',
            textColor: Colors.white,
            onPressed: () {
              openAppSettings();
            },
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return false;
    }

    if (!status.isGranted) {
      status = await Permission.microphone.request();
      if (!status.isGranted) {
        if (!mounted) {
          return false;
        }
        final isDeniedForever = status.isPermanentlyDenied;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isDeniedForever
                  ? 'Debes habilitar el micrófono desde configuración para grabar.'
                  : 'Se requieren permisos de micrófono para grabar.',
            ),
            action: isDeniedForever
                ? SnackBarAction(
                    label: 'Abrir',
                    textColor: Colors.white,
                    onPressed: () {
                      openAppSettings();
                    },
                  )
                : null,
            backgroundColor: Colors.redAccent,
          ),
        );
        return false;
      }
    }

    return true;
  }

  Future<void> _toggleAudioRecording() async {
    if (_isLoading) {
      return;
    }

    if (kIsWeb) {
      try {
        if (await _audioRecorder.isRecording()) {
          final result = await _audioRecorder.stop();
          if (result != null) {
            setState(() {
              _isRecordingAudio = false;
            });
            await _handleAudioMessage(result);
          }
        } else {
          final hasPermission = await _ensureMicrophonePermission();
          if (!hasPermission) {
            return;
          }
          await _audioRecorder.start(const RecordConfig(encoder: AudioEncoder.opus), path: '');
          setState(() {
            _isRecordingAudio = true;
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo grabar audio: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    try {
      if (_isRecordingAudio) {
        final result = await _recorderController.stop();
        if (!mounted) {
          return;
        }
        setState(() {
          _isRecordingAudio = false;
        });
        final recordedPath =
            (result != null && result.trim().isNotEmpty)
                ? result
                : _currentRecordingPath;
        _currentRecordingPath = null;
        if (recordedPath == null || recordedPath.trim().isEmpty) {
          return;
        }
        final parts = recordedPath.split(RegExp(r'[\\/]'));
        final derivedFileName =
            parts.isNotEmpty && parts.last.isNotEmpty ? parts.last : null;
        await _handleAudioMessage(
          recordedPath,
          fileName: derivedFileName,
        );
      } else {
        final outputPath = await _createRecordingPath();
        final hasPermission = await _ensureMicrophonePermission();
        if (!hasPermission) {
          return;
        }

        await _recorderController.record(path: outputPath);

        if (!mounted) {
          return;
        }
        setState(() {
          _isRecordingAudio = true;
          _currentRecordingPath = outputPath;
        });
      }
    } on Exception catch (e) {
      try {
        await _recorderController.stop();
      } catch (_) {}
      _currentRecordingPath = null;
      if (!mounted) {
        return;
      }
      setState(() {
        _isRecordingAudio = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo grabar audio: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _sendSuggestedPrompt(String text) {
    if (_isLoading) {
      return;
    }
    _handleUserMessage(text);
  }

  void _handleUserMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _scrollToBottom();
    _getAIResponse(text);
  }

  Future<void> _handleAudioMessage(
    String audioPath, {
    String? fileName,
    bool resetConversation = false,
  }) async {
    if (_isLoading) {
      return;
    }

    final path = audioPath.trim();
    if (path.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final AIAudioReply reply;
      if (kIsWeb) {
        reply = await _aiChatService.sendAudioFromUrl(
          audioUrl: path,
          fileName: fileName,
          conversationId: _conversationId,
          resetConversation: resetConversation,
        );
      } else {
        reply = await _aiChatService.sendAudioMessage(
          audioFilePath: path,
          fileName: fileName,
          conversationId: _conversationId,
          resetConversation: resetConversation,
        );
      }

      if (!mounted) {
        return;
      }
      setState(() {
        final response = reply.response.trim();
        _conversationId = reply.conversationId ?? _conversationId;
        if (response.isNotEmpty) {
          _messages.add(ChatMessage(text: response, isUser: false));
        }
      });
    } on AIChatException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _messages.add(ChatMessage(text: e.message, isUser: false));
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      const fallback = 'Ocurrió un error al procesar el audio.';
      setState(() {
        _messages.add(ChatMessage(text: fallback, isUser: false));
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo procesar el audio.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  // Mueve el scroll hasta el final de la lista
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: kPrimaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: kPrimaryColor),
            SizedBox(width: 8),
            Text(
              'PlanIA',
              style: TextStyle(
                color: kPrimaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // --- Área de Mensajes ---
          Expanded(
            child: _messages.length == 1
                ? _buildInitialSuggestions() // Muestra sugerencias si solo está el saludo
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),

          // --- Indicador de "Escribiendo..." ---
          if (_isLoading) _buildTypingIndicator(),

          // --- Área de Entrada de Texto ---
          _buildTextInputArea(),
        ],
      ),
    );
  }

  // --- Widgets Helpers ---

  Widget _buildInitialSuggestions() {
    return Column(
      children: [
        _buildMessageBubble(_messages[0]), // Muestra el mensaje de bienvenida
        const SizedBox(height: 24),
        const Text(
          "O prueba con estas ideas:",
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          alignment: WrapAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _sendSuggestedPrompt('Un plan barato para hoy'),
              child: const Text('¿Plan barato para hoy?'),
            ),
            ElevatedButton(
              onPressed: () =>
                  _sendSuggestedPrompt('Recomiéndame un restaurante'),
              child: const Text('Recomiéndame un restaurante'),
            ),
            ElevatedButton(
              onPressed: () => _sendSuggestedPrompt('¿Qué hacer en El Ávila?'),
              child: const Text('¿Qué hacer en El Ávila?'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: isUser ? kPrimaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomLeft: isUser
                ? const Radius.circular(20)
                : const Radius.circular(0),
            bottomRight: isUser
                ? const Radius.circular(0)
                : const Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
            ),
          ],
        ),
        child: Text(
          message.text,
          style: TextStyle(color: isUser ? Colors.white : Colors.black87),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: kPrimaryColor,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "Plancito está escribiendo...",
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInputArea() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor:
                  _isRecordingAudio ? Colors.redAccent : kPrimaryColor,
              child: IconButton(
                icon: Icon(
                  _isRecordingAudio ? Icons.stop : Icons.mic,
                  color: Colors.white,
                ),
                onPressed:
                    _isLoading ? null : () => _toggleAudioRecording(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: 'Escribe tu plan ideal...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: kBackgroundColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: kPrimaryColor,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
