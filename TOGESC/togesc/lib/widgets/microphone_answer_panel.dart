import 'package:flutter/material.dart';

import '../app/design_tokens.dart';
import '../services/microphone_pitch_service.dart';
import 'togesc_ui.dart';

/// Panel experimental de respuesta por microfono (Fase 7E-3).
class MicrophoneAnswerPanel extends StatefulWidget {
  const MicrophoneAnswerPanel({
    super.key,
    required this.requiredNotes,
    required this.onNoteDetected,
    required this.onSubmit,
  });

  final int requiredNotes;
  final ValueChanged<String> onNoteDetected;
  final VoidCallback onSubmit;

  @override
  State<MicrophoneAnswerPanel> createState() => _MicrophoneAnswerPanelState();
}

class _MicrophoneAnswerPanelState extends State<MicrophoneAnswerPanel> {
  bool _listening = false;
  String? _status;

  @override
  void dispose() {
    MicrophonePitchService.stopListening();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_listening) {
      await MicrophonePitchService.stopListening();
      setState(() {
        _listening = false;
        _status = 'Microfono detenido.';
      });
      return;
    }

    final started = await MicrophonePitchService.startListening(
      onNoteDetected: (note) {
        widget.onNoteDetected(note);
        if (!mounted) return;
        setState(() => _status = 'Detectada: $note');
      },
      onStatus: (message) {
        if (!mounted) return;
        setState(() => _status = message);
      },
    );

    setState(() => _listening = started);
  }

  @override
  Widget build(BuildContext context) {
    return TogescCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.mic_rounded,
                color: _listening
                    ? DesignTokens.primaryContainer
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Modo canto (experimental)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            MicrophonePitchService.isSupported
                ? 'Canta o tararea la nota. El audio no se sube a internet.'
                : 'Disponible en web. En movil usa piano o texto por ahora.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (_status != null) ...[
            const SizedBox(height: 8),
            Text(
              _status!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: DesignTokens.primaryContainer,
                  ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed:
                MicrophonePitchService.isSupported ? _toggleListening : null,
            icon: Icon(_listening ? Icons.stop_rounded : Icons.mic_none_rounded),
            label: Text(_listening ? 'Detener microfono' : 'Escuchar nota'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: widget.onSubmit,
            icon: const Icon(Icons.check_rounded),
            label: Text('Enviar (${widget.requiredNotes} nota(s))'),
          ),
        ],
      ),
    );
  }
}
