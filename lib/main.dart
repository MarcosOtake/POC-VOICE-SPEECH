import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Comandos de Voz',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const VoiceCommandApp(),
    );
  }
}

class VoiceCommandApp extends StatefulWidget {
  const VoiceCommandApp({super.key});

  @override
  State<VoiceCommandApp> createState() => _VoiceCommandAppState();
}

class _VoiceCommandAppState extends State<VoiceCommandApp> {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  final List<String> _produtosCadastrados = [
    'cerveja',
    'lanche',
    'hot dog',
    'caipirinha',
    'churrasco',
    'refrigerante'
  ];
  final List<String> _produtosSelecionados = [];

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    var status = await Permission.microphone.request();
    if (status.isGranted) {
      _speechEnabled = await _speechToText.initialize();
    } else {
      print('Permissão do microfone negada');
    }
    setState(() {});
  }

  void _startListening() async {
    if (_speechEnabled) {
      await _speechToText.listen(
        onResult: _onSpeechResult,
        localeId: 'pt_BR', // Força reconhecimento em português
      );
    } else {
      print("Speech recognition not available");
    }
    setState(() {});
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  // void _onSpeechResult(SpeechRecognitionResult result) {
  //   setState(() {
  //     _lastWords = result.recognizedWords;
  //     _processCommand(_lastWords);
  //   });
  // }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
    });

    // Só processa o comando se for o resultado final
    if (result.finalResult) {
      _processCommand(result.recognizedWords);
    }
  }

  void _processCommand(String command) {
    if (command.contains('adicionar')) {
      final itemParaAdicionar = _extractItem(command, 'adicionar');
      if (_produtosCadastrados.contains(itemParaAdicionar)) {
        setState(() {
          _produtosSelecionados.add(itemParaAdicionar);
        });
      } else {
        print('Produto "$itemParaAdicionar" não cadastrado.');
      }
    } else if (command.contains('remover') || command.contains('remova')) {
      final itemParaRemover = _extractItem(command, 'remover');
      if (_produtosCadastrados.contains(itemParaRemover)) {
        setState(() {
          _produtosSelecionados.remove(itemParaRemover);
        });
      } else {
        print(
            'Produto "$itemParaRemover" não está na lista de produtos cadastrados.');
      }
    }
  }

  String _extractItem(String command, String triggerWord) {
    final index = command.indexOf(triggerWord);
    if (index != -1) {
      final remainingText =
          command.substring(index + triggerWord.length).trim();
      final firstWord = remainingText.split(' ').first;
      if (_produtosCadastrados.contains(firstWord)) {
        return firstWord;
      }
    }
    return '';
  }

  Map<String, int> _contarProdutos() {
    final counts = <String, int>{};
    for (final produto in _produtosSelecionados) {
      counts[produto] = (counts[produto] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final produtosContados = _contarProdutos();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comandos de Voz'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Fale um comando:',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            Text(
              _speechToText.isListening
                  ? 'Ouvindo...'
                  : 'Clique no botão para falar',
              style: TextStyle(
                fontSize: 16,
                fontStyle: _speechToText.isListening
                    ? FontStyle.italic
                    : FontStyle.normal,
              ),
            ),
            const SizedBox(height: 30),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Card(
                  margin: const EdgeInsets.all(20),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Produtos Selecionados:',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        produtosContados.isEmpty
                            ? const Text('Nenhum produto selecionado.')
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: produtosContados.entries.map((entry) {
                                  return Text(
                                    '${entry.value} x ${entry.key[0].toUpperCase()}${entry.key.substring(1)}',
                                    style: const TextStyle(fontSize: 18),
                                  );
                                }).toList(),
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _speechToText.isListening ? _stopListening : _startListening,
        tooltip: _speechToText.isListening ? 'Parar de ouvir' : 'Ouvir',
        child: Icon(_speechToText.isListening ? Icons.mic_off : Icons.mic),
      ),
    );
  }
}
