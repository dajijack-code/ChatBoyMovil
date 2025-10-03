import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat_mode.dart';
import '../viewmodels/chat_view_model.dart';
import '../widgets/draggable_mic_button.dart';
import '../widgets/message_bubble.dart';
import '../widgets/mode_selector.dart';
import '../widgets/status_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Image.asset('assets/logo.png', height: 32, errorBuilder: (_, __, ___) => const Icon(Icons.mic)),
                const SizedBox(width: 12),
                const Text('ChatBoy Voice'),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => _openSettings(context, vm),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(64),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ModeSelector(
                  currentMode: vm.mode,
                  onModeSelected: (mode) {
                    vm.selectMode(mode);
                    if (mode == ChatMode.hotword) {
                      vm.startListening();
                    } else {
                      vm.stopListening(cancel: true);
                    }
                  },
                ),
              ),
            ),
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  StatusBanner(
                    status: vm.errorMessage,
                    onRetry: vm.loadPreferences,
                  ),
                  if (vm.currentPartial != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Escuchando: ${vm.currentPartial}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      reverse: false,
                      itemCount: vm.messages.length,
                      itemBuilder: (context, index) {
                        final message = vm.messages[index];
                        return MessageBubble(message: message);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: const InputDecoration(
                              hintText: 'Escribe un mensaje',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: vm.isLoading
                              ? null
                              : () {
                                  final text = _controller.text;
                                  _controller.clear();
                                  vm.sendText(text);
                                },
                          child: const Text('Enviar'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              DraggableMicButton(
                initialOffset: vm.micPosition,
                onPressed: () async {
                  if (vm.isAudioPlaying) {
                    vm.interruptAudio();
                  }
                  switch (vm.mode) {
                    case ChatMode.dictation:
                    case ChatMode.openChat:
                      if (vm.isListening) {
                        await vm.stopListening();
                      } else {
                        await vm.startListening();
                      }
                      break;
                    case ChatMode.hotword:
                      if (!vm.isListening) {
                        await vm.startListening();
                      }
                      break;
                    case ChatMode.pushToTalk:
                      // handled by tap events
                      break;
                  }
                },
                onTapDown: vm.mode == ChatMode.pushToTalk
                    ? () async {
                        if (vm.isAudioPlaying) {
                          vm.interruptAudio();
                        }
                        await vm.startListening();
                      }
                    : null,
                onTapUp: vm.mode == ChatMode.pushToTalk
                    ? () {
                        vm.stopListening();
                      }
                    : null,
                onPositionChanged: vm.updateMicPosition,
                isRecording: vm.currentPartial != null,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openSettings(BuildContext context, ChatViewModel vm) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final tokenController = TextEditingController(text: vm.apiToken ?? '');
        final endpointController = TextEditingController(text: vm.apiEndpoint ?? '');
        final hotwordController = TextEditingController(text: vm.hotword ?? '');
        final stopPhraseController = TextEditingController(text: vm.stopPhrase ?? '');
        final voiceController = TextEditingController(text: vm.voice ?? '');
        final googleKeyController = TextEditingController(text: vm.googleTtsKey ?? '');
        return Padding(
          padding: MediaQuery.of(context).viewInsets.add(const EdgeInsets.all(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tokenController,
                decoration: const InputDecoration(labelText: 'Token'),
              ),
              TextField(
                controller: endpointController,
                decoration: const InputDecoration(labelText: 'Endpoint'),
              ),
              TextField(
                controller: hotwordController,
                decoration: const InputDecoration(labelText: 'Frase de activación'),
              ),
              TextField(
                controller: stopPhraseController,
                decoration: const InputDecoration(labelText: 'Frase de terminación'),
              ),
              TextField(
                controller: voiceController,
                decoration: const InputDecoration(labelText: 'Voz preferida'),
              ),
              TextField(
                controller: googleKeyController,
                decoration: const InputDecoration(labelText: 'Google TTS API Key'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  await vm.savePreferences(
                    token: tokenController.text,
                    endpoint: endpointController.text,
                    hotword: hotwordController.text,
                    stopPhrase: stopPhraseController.text,
                    voice: voiceController.text,
                    googleTtsKey: googleKeyController.text,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
        );
      },
    );
  }
}
