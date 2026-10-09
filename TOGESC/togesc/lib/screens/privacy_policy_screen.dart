import 'package:flutter/material.dart';

import '../app/design_tokens.dart';
import '../widgets/info_views.dart';
import '../widgets/togesc_ui.dart';

/// Política de privacidad (Stitch privacy_premium).
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _lastUpdated = '9 de octubre de 2026';

  @override
  Widget build(BuildContext context) {
    return TogescScaffold(
      title: 'Política de privacidad',
      body: ListView(
        padding: const EdgeInsets.all(DesignTokens.marginMobile),
        children: const [
          PrivacyHeroHeader(lastUpdated: _lastUpdated),
          SizedBox(height: DesignTokens.spacingLg),
          PolicySection(
            title: 'Resumen',
            body:
                'TOGESC guarda tu progreso de entrenamiento en tu dispositivo. '
                'No mostramos publicidad ni vendemos tus datos. Sí registramos '
                'eventos de uso (analítica propia, activa por defecto) y '
                'errores técnicos (Sentry). Si activas una cuenta opcional '
                '(Supabase), tu progreso SRS se sincroniza cifrado en tránsito '
                'y solo tu usuario puede leerlo. Abajo se detalla cada servicio '
                'que recibe datos.',
          ),
          PolicySection(
            title: 'Datos que se guardan en tu dispositivo',
            body:
                'Tu progreso de entrenamiento (pesos SRS, estadísticas, '
                'historial local de sesiones y preferencias como onboarding '
                'completado) se almacena en tu dispositivo mediante '
                'almacenamiento local del sistema (SharedPreferences en '
                'móvil/escritorio; almacenamiento del navegador en web). Si '
                'inicias sesión, la sesión de Supabase también se guarda ahí.',
          ),
          PolicySection(
            title: 'Cuenta opcional y sincronización',
            body:
                'Puedes entrenar sin registrarte. Si creas una cuenta, '
                'Supabase guarda tu email, tu contraseña cifrada (hash) y un '
                'JSON con tu progreso SRS vinculado a tu identificador de '
                'usuario, en Postgres con políticas RLS. También guarda el '
                'estado de tu plan (gratuito o Pro).',
          ),
          PolicySection(
            title: 'Analítica de uso',
            body:
                'La analítica está activa por defecto, tengas cuenta o no. La '
                'app envía a nuestra base de datos en Supabase eventos como '
                'abrir la app, empezar un modo, completar una ronda (modo y si '
                'acertaste), ver la pantalla de planes, iniciar una prueba y '
                'terminar una sincronización. Si has iniciado sesión, cada '
                'evento lleva tu identificador de usuario (user_id); sin '
                'sesión se guarda sin identificador. No usamos analítica de '
                'terceros. Hoy la app no tiene un interruptor para '
                'desactivarla: puedes usarla sin cuenta para que los eventos '
                'no se asocien a ti, y quien compila la app puede desactivarla '
                'por completo con ANALYTICS_ENABLED=false. Si quieres que '
                'borremos tus eventos, escríbenos (ver Contacto).',
          ),
          PolicySection(
            title: 'Encuesta de satisfacción',
            body:
                'De vez en cuando la app muestra una encuesta breve. Si la '
                'respondes, enviamos la puntuación y, si lo escribes, tu '
                'comentario de texto libre, como un evento de analítica más '
                '(con tu user_id si has iniciado sesión). No escribas datos '
                'personales en el comentario.',
          ),
          PolicySection(
            title: 'Errores técnicos (Sentry)',
            body:
                'Usamos Sentry para recibir informes de fallos y una muestra '
                'del 20 % de trazas de rendimiento: mensaje de error, pila de '
                'llamadas, versión de la app y datos del dispositivo o '
                'navegador. No enviamos tu email ni tu nombre, pero Sentry '
                'recibe tu dirección IP al conectarse.',
          ),
          PolicySection(
            title: 'Fuentes y motor gráfico (Google)',
            body:
                'La app descarga sus tipografías desde Google Fonts '
                '(fonts.gstatic.com) al abrirse. En la versión web, además, '
                'el motor gráfico de Flutter (CanvasKit) se descarga desde '
                'www.gstatic.com y la página de presentación carga fuentes '
                'desde fonts.googleapis.com. En esas descargas Google recibe tu '
                'dirección IP y datos técnicos del navegador.',
          ),
          PolicySection(
            title: 'Pagos (cuando se activen)',
            body:
                'Hoy los pagos no están activos. Cuando se active la '
                'suscripción Pro: en web, el pago se hace en Stripe, al que '
                'enviamos tu identificador de usuario y tu email para '
                'rellenar el formulario; en Android e iOS, la compra pasa por '
                'Google Play o App Store y RevenueCat, que recibe tu '
                'identificador de usuario. Nosotros nunca vemos los datos de '
                'tu tarjeta; solo recibimos el estado de la suscripción.',
          ),
          PolicySection(
            title: 'Quién trata tus datos',
            body:
                'Supabase actúa como encargado del tratamiento: aloja la '
                'cuenta, el progreso sincronizado, el estado del plan y la '
                'analítica. Además intervienen Sentry (errores), Vercel '
                '(alojamiento de la web, registra la IP en sus logs), Google '
                '(fuentes y CanvasKit) y, cuando se activen los pagos, Stripe '
                'y RevenueCat. No vendemos ni cedemos datos con fines '
                'comerciales.',
          ),
          PolicySection(
            title: 'Exportación de datos',
            body:
                'En Cuenta puedes exportar un archivo JSON con tu progreso '
                'SRS, preferencias e historial local de sesiones. En web se '
                'descarga el archivo; en móvil se copia al portapapeles. '
                'Sirve para respaldo o portabilidad (RGPD).',
          ),
          PolicySection(
            title: 'Audio y micrófono',
            body:
                'Los ejercicios se sintetizan en tu dispositivo. El modo canto '
                'experimental usa el micrófono solo en tu dispositivo para '
                'detectar la nota; el audio no se graba, no se almacena ni se '
                'envía a internet.',
          ),
          PolicySection(
            title: 'Eliminación y conservación',
            body:
                'Puedes borrar tu progreso local desde Estadísticas '
                '(Reiniciar progreso) o desinstalando la app. Si tienes '
                'cuenta, en Cuenta puedes eliminarla: se borran tu usuario, '
                'el progreso sincronizado y el estado del plan en Supabase. '
                'Los eventos de analítica ya enviados se conservan, pero se '
                'desvinculan de tu usuario (el user_id pasa a vacío). Aún no '
                'hay un plazo de borrado automático para la analítica. El '
                'progreso local se conserva hasta que lo reinicies o '
                'desinstales la app.',
          ),
          PolicySection(
            title: 'Contacto',
            body:
                'Proyecto open source en GitHub (Raikadier/togesc). Para '
                'consultas, ejercer tus derechos o pedir el borrado de tus '
                'datos, abre un issue en el repositorio sin incluir datos '
                'personales y te indicaremos un canal privado.',
          ),
        ],
      ),
    );
  }
}
