import 'package:flutter/material.dart';

import '../app/design_tokens.dart';
import '../widgets/info_views.dart';
import '../widgets/togesc_ui.dart';

/// Politica de privacidad (Fase 7E-1).
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _lastUpdated = '20 de junio de 2026';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TogescScaffold(
      title: 'Politica de privacidad',
      body: ListView(
        padding: const EdgeInsets.all(DesignTokens.marginMobile),
        children: [
          Text(
            'Ultima actualizacion: $_lastUpdated',
            style: theme.textTheme.bodySmall?.copyWith(
              color: DesignTokens.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingLg),
          const PolicySection(
            title: 'Resumen',
            body:
                'TOGESC guarda tu progreso de entrenamiento en tu dispositivo. '
                'No hay analitica ni publicidad. Si activas una cuenta '
                'opcional (Supabase), tu progreso SRS se sincroniza de forma '
                'cifrada en tránsito con tu email y contrasena; solo tu '
                'usuario puede leer esos datos.',
          ),
          const PolicySection(
            title: 'Datos que se guardan',
            body:
                'Tu progreso de entrenamiento (pesos SRS, estadisticas, '
                'historial local de sesiones y preferencias como onboarding '
                'completado) se almacena en tu dispositivo mediante '
                'almacenamiento local del sistema (SharedPreferences en '
                'movil/escritorio; almacenamiento del navegador en web).',
          ),
          const PolicySection(
            title: 'Cuenta opcional y sincronizacion',
            body:
                'Puedes entrenar sin registrarte. Si creas una cuenta, '
                'almacenamos en Supabase (Postgres con politicas RLS) un '
                'JSON con tu progreso SRS vinculado a tu identificador de '
                'usuario. No vendemos ni compartimos esos datos con terceros '
                'con fines comerciales.',
          ),
          const PolicySection(
            title: 'Exportacion de datos',
            body:
                'En Cuenta puedes exportar un archivo JSON con tu progreso '
                'SRS, preferencias e historial local de sesiones. En web se '
                'descarga el archivo; en movil se copia al portapapeles. '
                'Sirve para respaldo o portabilidad (GDPR).',
          ),
          const PolicySection(
            title: 'Datos que no recopilamos',
            body:
                'No grabamos microfono ni subimos audio. No usamos servicios '
                'de analitica ni publicidad de terceros.',
          ),
          const PolicySection(
            title: 'Audio',
            body:
                'Los ejercicios se sintetizan en tu dispositivo. No se graba '
                'microfono ni se sube audio a internet, salvo el modo canto '
                'experimental en web: el microfono se usa solo en tu '
                'navegador para detectar la nota y no se almacena ni envia.',
          ),
          const PolicySection(
            title: 'Eliminacion de datos',
            body:
                'Puedes borrar tu progreso local desde Estadisticas '
                '(Reiniciar progreso) o desinstalando la app. Si tienes '
                'cuenta, en Cuenta puedes eliminarla: se borra tu usuario '
                'en Supabase y el progreso sincronizado en la nube. El '
                'progreso local en el dispositivo se conserva hasta que lo '
                'reinicies o desinstales la app.',
          ),
          const PolicySection(
            title: 'Cambios futuros',
            body:
                'Si se anaden analitica, pagos u otros servicios, esta politica '
                'se actualizara antes del lanzamiento.',
          ),
          const PolicySection(
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
