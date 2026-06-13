import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/srs_provider.dart';

/// Pantalla de estadisticas del sistema SRS.
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(srsStatisticsProvider);

    if (stats.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Estadisticas')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final accuracy = stats['accuracy_percentage'] as double? ?? 0.0;
    final totalSeen = stats['total_seen'] as int? ?? 0;
    final learningPhase = stats['learning_phase'] as int? ?? 0;
    final graduated = stats['graduated'] as int? ?? 0;
    final totalNotes = stats['total_notes'] as int? ?? 12;
    final overdueCount = stats['overdue_count'] as int? ?? 0;
    final hardestNotes = stats['hardest_notes'] as List<dynamic>? ?? [];
    final easiestNotes = stats['easiest_notes'] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadisticas'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Resumen general
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resumen General',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _StatTile(
                      icon: Icons.percent,
                      label: 'Precision global',
                      value: '$accuracy%',
                      color: accuracy >= 80
                          ? Colors.green
                          : accuracy >= 50
                              ? Colors.orange
                              : Colors.red,
                    ),
                    _StatTile(
                      icon: Icons.visibility,
                      label: 'Total de intentos',
                      value: '$totalSeen',
                      color: Colors.blue,
                    ),
                    _StatTile(
                      icon: Icons.school,
                      label: 'En aprendizaje',
                      value: '$learningPhase / $totalNotes',
                      color: Colors.orange,
                    ),
                    _StatTile(
                      icon: Icons.check_circle,
                      label: 'Consolidadas',
                      value: '$graduated / $totalNotes',
                      color: Colors.green,
                    ),
                    if (overdueCount > 0)
                      _StatTile(
                        icon: Icons.warning,
                        label: 'Pendientes de revision',
                        value: '$overdueCount',
                        color: Colors.red,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Progreso visual
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Progreso',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: totalNotes > 0 ? graduated / totalNotes : 0,
                      backgroundColor: Colors.grey.shade200,
                      minHeight: 12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$graduated de $totalNotes notas consolidadas',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Notas dificiles
            if (hardestNotes.isNotEmpty)
              _NotesSection(
                title: 'Notas Mas Dificiles',
                notes: hardestNotes.cast<String>(),
                color: Colors.red,
                icon: Icons.trending_up,
              ),
            const SizedBox(height: 12),
            // Notas faciles
            if (easiestNotes.isNotEmpty)
              _NotesSection(
                title: 'Notas Mas Faciles',
                notes: easiestNotes.cast<String>(),
                color: Colors.green,
                icon: Icons.trending_down,
              ),
            const SizedBox(height: 24),
            // Boton reset
            OutlinedButton.icon(
              onPressed: () => _showResetDialog(context, ref),
              icon: const Icon(Icons.restart_alt, color: Colors.red),
              label: const Text(
                'Reiniciar progreso',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reiniciar progreso?'),
        content: const Text(
          'Se perderan todos los datos de entrenamiento. Esta accion no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref.read(srsSystemProvider.notifier).resetProgress();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Progreso reiniciado')),
              );
            },
            child: const Text(
              'Reiniciar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesSection extends StatelessWidget {
  final String title;
  final List<String> notes;
  final Color color;
  final IconData icon;

  const _NotesSection({
    required this.title,
    required this.notes,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: notes.map((note) => Chip(
                label: Text(note, style: TextStyle(color: color)),
                backgroundColor: color.withValues(alpha: 0.1),
                side: BorderSide(color: color.withValues(alpha: 0.3)),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
