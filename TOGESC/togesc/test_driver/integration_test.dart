// Driver de `flutter drive` para integration_test/ (web y dispositivos).
//
// Guarda cada captura de `IntegrationTestWidgetsFlutterBinding.takeScreenshot`
// en build/evidence/<plataforma>/<nombre>.png. El test nombra las capturas
// «<plataforma>__<nombre>» (p. ej. «android__01_home»); sin prefijo se usa
// la variable de entorno E2E_PLATFORM o 'unknown'.
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() {
  return integrationDriver(
    onScreenshot:
        (String name, List<int> image, [Map<String, Object?>? args]) async {
          var platform = Platform.environment['E2E_PLATFORM'] ?? 'unknown';
          var file = name;
          final split = name.indexOf('__');
          if (split > 0) {
            platform = name.substring(0, split);
            file = name.substring(split + 2);
          }
          final out = File('build/evidence/$platform/$file.png');
          await out.create(recursive: true);
          await out.writeAsBytes(image);
          stdout.writeln('evidence: ${out.path}');
          return true;
        },
  );
}
