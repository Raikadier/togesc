import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/audio_provider.dart';

/// Reproduce un tono de prueba (440 Hz) para verificar el dispositivo.
class AudioTestButton extends ConsumerWidget {
  final bool outlined;

  const AudioTestButton({super.key, this.outlined = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final button = outlined
        ? OutlinedButton.icon(
            onPressed: () => _runTest(context, ref),
            icon: const Icon(Icons.volume_up_rounded),
            label: const Text('Probar sonido'),
          )
        : FilledButton.tonalIcon(
            onPressed: () => _runTest(context, ref),
            icon: const Icon(Icons.volume_up_rounded),
            label: const Text('Probar sonido'),
          );

    return SizedBox(width: double.infinity, child: button);
  }

  Future<void> _runTest(BuildContext context, WidgetRef ref) async {
    final audio = ref.read(audioPlayerServiceProvider);
    audio.captureUserGesture();
    final ready = await audio.waitUntilReady();
    if (!context.mounted) return;

    if (!ready) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo iniciar el audio. Comprueba el volumen del dispositivo.',
          ),
        ),
      );
      return;
    }

    final ok = await audio.testAudio();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? '¿Oiste el tono de prueba? Si no, sube el volumen en Cuenta.'
              : 'No se pudo reproducir el tono. Revisa permisos y volumen.',
        ),
      ),
    );
  }
}
