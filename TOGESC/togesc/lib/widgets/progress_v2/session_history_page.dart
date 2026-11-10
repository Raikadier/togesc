import 'package:flutter/material.dart';

import '../session_history_card.dart';
import '../togesc_ui.dart';

/// Historial completo de sesiones (Pro, D7). Se abre desde «Historial» en
/// Progreso con `Navigator.push`, sin ruta propia en el router.
class SessionHistoryPage extends StatelessWidget {
  const SessionHistoryPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const SessionHistoryPage());
  }

  @override
  Widget build(BuildContext context) {
    return const TogescScaffold(
      title: 'Historial',
      body: TogescPageBody(child: SessionHistoryCard()),
    );
  }
}
