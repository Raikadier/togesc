import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/router.dart';
import '../providers/router_provider.dart';
import '../services/app_preferences.dart';

/// Introduccion pedagogica: por que SRS, octavas y cluster de limpieza.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Como funciona'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Bienvenido al entrenador de oido absoluto',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Esta app usa estrategias pedagógicas comprobadas. '
            'Tres ideas clave antes de empezar:',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          _SectionCard(
            icon: Icons.psychology,
            color: Colors.indigo,
            title: 'Repeticion espaciada (SRS)',
            body:
                'El sistema repite mas las notas que te cuestan y espacia las que '
                'ya dominas. Asi consolidas memoria a largo plazo, no memorizacion '
                'de un dia.',
          ),
          _SectionCard(
            icon: Icons.tune,
            color: Colors.teal,
            title: 'Variacion de octavas y timbres',
            body:
                'Las notas suenan en distintas octavas y con distintos colores '
                'timbrales para que aprendas la clase de altura (Do, Re, Mi...) '
                'y no una frecuencia fija en Hz.',
          ),
          _SectionCard(
            icon: Icons.blur_on,
            color: Colors.deepOrange,
            title: 'Limpieza tonal',
            body:
                'Tras cada ejercicio oiras un sonido caotico breve que rompe el '
                'anclaje al tono anterior. Asi entrenas identificacion absoluta, '
                'no memoria relativa entre ejercicios.',
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => _complete(context),
            child: const Text('Entendido, empezar'),
          ),
        ],
      ),
    );
  }

  Future<void> _complete(BuildContext context) async {
    final prefs = AppPreferences(await SharedPreferences.getInstance());
    await prefs.setOnboardingComplete(true);
    refreshAppRouter();
    if (context.mounted) {
      context.go(AppRoutes.home);
    }
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _SectionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
