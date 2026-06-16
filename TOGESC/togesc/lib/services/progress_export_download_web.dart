import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart';

/// Descarga CSV en navegador web.
void downloadCsvWeb(String csv, {String filename = 'togesc_progreso.csv'}) {
  final bytes = Uint8List.fromList(utf8.encode(csv));
  final blob = Blob([bytes.toJS].toJS);
  final url = URL.createObjectURL(blob);
  final anchor = HTMLAnchorElement()
    ..href = url
    ..download = filename;
  document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
  URL.revokeObjectURL(url);
}
