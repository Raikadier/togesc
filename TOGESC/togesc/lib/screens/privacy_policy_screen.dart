import 'package:flutter/material.dart';

/// Politica de privacidad (fase sin cuentas ni backend).
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _lastUpdated = '14 de junio de 2026';

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Politica de privacidad'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Ultima actualizacion: $_lastUpdated',
            style: TextStyle(color: muted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          const _PolicySection(
            title: 'Resumen',
            body:
                'TOGESC guarda tu progreso de entrenamiento en tu dispositivo. '
                'No hay analitica ni publicidad. Si activas una cuenta '
                'opcional (Supabase), tu progreso SRS se sincroniza de forma '
                'cifrada en tránsito con tu email y contrasena; solo tu '
                'usuario puede leer esos datos.',
          ),
          const _PolicySection(
            title: 'Datos que se guardan',
            body:
                'Tu progreso de entrenamiento (pesos SRS, estadisticas y '
                'preferencias como onboarding completado) se almacena solo en '
                'tu dispositivo mediante almacenamiento local del sistema '
                '(SharedPreferences en movil/escritorio; almacenamiento del '
                'navegador en web).',
          ),
          const _PolicySection(
            title: 'Cuenta opcional y sincronizacion',
            body:
                'Puedes entrenar sin registrarte. Si creas una cuenta, '
                'almacenamos en Supabase (Postgres con politicas RLS) un '
                'JSON con tu progreso SRS vinculado a tu identificador de '
                'usuario. No vendemos ni compartimos esos datos con terceros '
                'con fines comerciales.',
          ),
          const _PolicySection(
            title: 'Datos que no recopilamos',
            body:
                'No grabamos microfono ni subimos audio. No usamos servicios '
                'de analitica ni publicidad de terceros.',
          ),
          const _PolicySection(
            title: 'Audio',
            body:
                'Los ejercicios se sintetizan en tu dispositivo. No se graba '
                'microfono ni se sube audio a internet.',
          ),
          const _PolicySection(
            title: 'Eliminacion de datos',
            body:
                'Puedes borrar tu progreso desinstalando la app o limpiando '
                'los datos del sitio en la configuracion del navegador (web). '
                'En futuras versiones puede anadirse un boton de restablecer '
                'progreso en la app.',
          ),
          const _PolicySection(
            title: 'Cambios futuros',
            body:
                'Si se anaden analitica, pagos u otros servicios, esta politica '
                'se actualizara antes del lanzamiento.',
          ),
          const _PolicySection(
            title: 'Contacto',
            body:
                'Proyecto open source en GitHub (Raikadier/togesc). Para '
                'consultas o incidencias, abre un issue en el repositorio.',
          ),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String body;

  const _PolicySection({
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(body),
        ],
      ),
    );
  }
}
