import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/router.dart';
import '../widgets/pedagogy_section_card.dart';

/// Informacion del proyecto y enfoque pedagogico.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acerca de TOGESC'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Entrenador de Oido Absoluto',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'TOGESC (TOne GEneration SCript) es una app educativa de codigo '
            'abierto para entrenar identificacion de alturas musicales con '
            'metodos basados en evidencia. El entrenamiento ocurre en tu '
            'dispositivo; la cuenta en la nube es opcional para sincronizar '
            'progreso entre dispositivos.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Como entrena la app',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const PedagogySectionCard(
            icon: Icons.psychology,
            color: Colors.indigo,
            title: 'Repeticion espaciada (SRS)',
            body:
                'El sistema repite mas las notas que te cuestan y espacia las '
                'que ya dominas. Asi consolidas memoria a largo plazo.',
          ),
          const PedagogySectionCard(
            icon: Icons.tune,
            color: Colors.teal,
            title: 'Variacion de octavas y timbres',
            body:
                'Las notas suenan en distintas octavas y timbres para que '
                'aprendas la clase de altura (Do, Re, Mi...) y no una '
                'frecuencia fija.',
          ),
          const PedagogySectionCard(
            icon: Icons.blur_on,
            color: Colors.deepOrange,
            title: 'Limpieza tonal',
            body:
                'Tras cada ejercicio oiras un sonido caotico breve que rompe '
                'el anclaje al tono anterior y favorece oido absoluto.',
          ),
          const SizedBox(height: 8),
          const PedagogySectionCard(
            icon: Icons.music_note,
            color: Colors.deepPurple,
            title: 'Modos de practica',
            body:
                'Una nota, intervalos, acordes, aleatorio y velocidad. '
                'Piano interactivo, entrada por texto y estadisticas locales.',
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.workspace_premium_outlined),
            title: const Text('Suscripcion Pro'),
            subtitle: const Text('Planes, prueba gratis y gestion'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.subscription),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.person_outline),
            title: const Text('Cuenta y sincronizacion'),
            subtitle: const Text('Opcional — vincular progreso entre dispositivos'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.account),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Politica de privacidad'),
            subtitle: const Text('Datos locales y cuenta opcional'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.privacy),
          ),
          const SizedBox(height: 8),
          Text(
            'Version 1.0.0 · Proyecto educativo open source',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
