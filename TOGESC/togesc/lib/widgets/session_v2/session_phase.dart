import 'package:flutter/widgets.dart';

import '../../app/design_tokens.dart';

/// Fase visible de la sesión v2 (1b/1d).
///
/// `idle` («Preparado», v2.1: siempre al entrar; el gesto de «Estoy listo»
/// desbloquea el audio, D4) → `listen` → `answer` → `result` →
/// (`cluster`) → `listen`… `paused` mientras la ronda está en pausa.
enum SessionPhase { idle, listen, answer, result, cluster, paused }

/// Textos y color de una fase. Todo el copy sale de datos reales (D10).
@immutable
class SessionPhaseCopy {
  final String overline;
  final String headline;
  final String? subtitle;
  final Color color;

  const SessionPhaseCopy({
    required this.overline,
    required this.headline,
    required this.color,
    this.subtitle,
  });

  /// Texto para el lector de pantalla (región viva).
  String get announcement =>
      subtitle == null ? '$overline. $headline' : '$overline. $headline. $subtitle';
}

/// Datos de la ronda necesarios para el copy.
@immutable
class SessionPhaseContext {
  final SessionPhase phase;

  /// Notas que pide la ronda (1 en «Una sola nota»).
  final int requiredNotes;

  /// Subtítulo de escucha ya compuesto («Piano · octava 4 · 1 nota»).
  final String listenDetail;

  /// Modo de envío: el usuario reactivó «Confirmar» en Ajustes.
  final bool confirmMode;

  /// Solo texto: no hay piano para responder.
  final bool textOnly;

  /// Resultado (solo en `result`).
  final bool? isCorrect;
  final List<String> correctLabels;
  final List<String> answerLabels;

  /// Avance automático activo (D2) o manual (accesibilidad).
  final bool autoAdvance;

  /// Meta de rondas cumplida en esta ronda.
  final bool goalReached;
  final int targetRounds;

  /// Aciertos seguidos tras esta ronda («¡N seguidas!» desde 3).
  final int streak;

  /// Notas foco ya formateadas («F#, C#, A#») para «Preparado».
  final List<String> focusLabels;

  const SessionPhaseContext({
    required this.phase,
    this.requiredNotes = 1,
    this.listenDetail = '',
    this.confirmMode = false,
    this.textOnly = false,
    this.isCorrect,
    this.correctLabels = const [],
    this.answerLabels = const [],
    this.autoAdvance = true,
    this.goalReached = false,
    this.targetRounds = 0,
    this.streak = 0,
    this.focusLabels = const [],
  });
}

String _joinNotes(List<String> labels) {
  if (labels.isEmpty) return '';
  if (labels.length == 1) return labels.first;
  final head = labels.sublist(0, labels.length - 1).join(', ');
  return '$head y ${labels.last}';
}

/// Copy de la fase (spec 1b). Función pura: la prueban los tests.
SessionPhaseCopy sessionPhaseCopy(SessionPhaseContext c) {
  final many = c.requiredNotes > 1;
  switch (c.phase) {
    case SessionPhase.idle:
      final parts = <String>[
        c.targetRounds > 0
            ? '${c.targetRounds} rondas'
            : 'Sin límite de rondas',
        many ? '${c.requiredNotes} notas' : '1 nota',
        if (c.focusLabels.isNotEmpty) 'foco en ${c.focusLabels.join(', ')}',
      ];
      return SessionPhaseCopy(
        overline: 'Preparado',
        headline: 'Ponte los auriculares',
        subtitle: parts.join(' · '),
        color: DesignTokens.sessionAccent,
      );
    case SessionPhase.listen:
      return SessionPhaseCopy(
        overline: 'Escuchando',
        headline: 'Escucha con atención',
        subtitle: c.listenDetail.isEmpty ? null : c.listenDetail,
        color: DesignTokens.sessionAccent,
      );
    case SessionPhase.answer:
      final String subtitle;
      if (c.textOnly) {
        subtitle = many
            ? 'Escribe las ${c.requiredNotes} notas y pulsa Intro.'
            : 'Escribe la nota y pulsa Intro.';
      } else if (c.confirmMode) {
        subtitle = many
            ? 'Toca las ${c.requiredNotes} teclas y pulsa Confirmar.'
            : 'Toca la tecla y pulsa Confirmar.';
      } else {
        subtitle = many
            ? 'Toca las ${c.requiredNotes} teclas — se envía al completar la '
                'selección.'
            : 'Toca la tecla — se envía al instante, sin confirmar.';
      }
      return SessionPhaseCopy(
        overline: 'Responde',
        headline: many ? '¿Qué notas escuchaste?' : '¿Qué nota escuchaste?',
        subtitle: subtitle,
        color: DesignTokens.sessionAmber,
      );
    case SessionPhase.result:
      final String? next;
      if (c.goalReached) {
        next = c.targetRounds > 0
            ? 'Objetivo cumplido: ${c.targetRounds} rondas. Preparando tu '
                'resumen…'
            : null;
      } else {
        next = c.autoAdvance
            ? 'Siguiente ronda en un momento…'
            : 'Pulsa «Siguiente ronda» cuando quieras.';
      }
      if (c.isCorrect ?? false) {
        return SessionPhaseCopy(
          overline: 'Correcto',
          headline: c.streak >= 3
              ? '¡${c.streak} seguidas!'
              : (many ? 'Bien identificadas' : 'Bien identificada'),
          subtitle: next,
          color: DesignTokens.sessionSuccess,
        );
      }
      final era = _joinNotes(c.correctLabels);
      final answered = _joinNotes(c.answerLabels);
      return SessionPhaseCopy(
        overline: 'Incorrecto',
        headline: answered.isEmpty
            ? 'Era $era'
            : 'Era $era, respondiste $answered',
        subtitle: c.goalReached
            ? next
            : (many
                ? 'Las teclas correctas quedan marcadas en verde.'
                : 'La tecla correcta queda marcada en verde.'),
        color: DesignTokens.sessionError,
      );
    case SessionPhase.cluster:
      return const SessionPhaseCopy(
        overline: 'Limpiando',
        headline: 'Limpiando el oído…',
        subtitle: 'Transición breve antes de la siguiente nota.',
        color: DesignTokens.sessionTextLabel,
      );
    case SessionPhase.paused:
      return const SessionPhaseCopy(
        overline: 'En pausa',
        headline: 'Sesión pausada',
        subtitle: 'El tiempo de respuesta está detenido.',
        color: DesignTokens.sessionTextLabel,
      );
  }
}
