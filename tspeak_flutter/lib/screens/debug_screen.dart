import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../utils/debug_logger.dart';
import '../services/api_service.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isTesting = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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

  Future<void> _testConnection() async {
    setState(() => _isTesting = true);
    final logger = DebugLogger();
    logger.log('🚀 === DÉBUT DU TEST DE CONNEXION ===');
    logger.log('📡 URL: ${ApiService.baseUrl}auth/login/');

    try {
      final api = context.read<ApiService>();
      logger.log('📤 Envoi POST avec: email=test@test.com password=test');
      final response = await api.post('auth/login/', data: {
        'email': 'Fatimata@gmail.com',
        'password': 'Fatimata05?',
      });
      logger.log('✅ Réponse reçue: ${response.statusCode}');
      logger.log('📦 Données: ${response.data}');
    } catch (e) {
      logger.log('❌ ERREUR: $e');
      logger.log('🔍 Type: ${e.runtimeType}');
    } finally {
      logger.log('🏁 === FIN DU TEST ===');
      if (mounted) setState(() => _isTesting = false);
    }
  }

  Color _colorForLine(String line) {
    if (line.contains('❌') || line.contains('ERREUR')) return Colors.red[300]!;
    if (line.contains('✅')) return Colors.green[300]!;
    if (line.contains('🚀') || line.contains('🏁')) return Colors.blue[300]!;
    if (line.contains('📤')) return Colors.orange[300]!;
    if (line.contains('📦')) return Colors.purple[300]!;
    return Colors.white70;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        title: const Text(
          '🛠️ Diagnostic Réseau',
          style: TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.white70),
            onPressed: () {
              final text = DebugLogger().logs.join('\n');
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logs copiés !')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.white70),
            onPressed: () => DebugLogger().clear(),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF161B22),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '🌐 ${ApiService.baseUrl}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isTesting ? null : _testConnection,
                  icon: _isTesting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.wifi_tethering, size: 16),
                  label: Text(_isTesting ? 'Test...' : 'Tester'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: DebugLogger(),
              builder: (context, _) {
                final logs = DebugLogger().logs;
                _scrollToBottom();
                if (logs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aucun log.\nAppuie sur "Tester" pour lancer un test de connexion.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38, fontFamily: 'monospace'),
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: logs.length,
                  itemBuilder: (ctx, i) => Text(
                    logs[i],
                    style: TextStyle(
                      color: _colorForLine(logs[i]),
                      fontFamily: 'monospace',
                      fontSize: 11,
                      height: 1.6,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
