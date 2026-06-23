import 'dart:math';

import '../constants/srs_constants.dart';

/// Datos completos de una nota en el sistema SRS.
class NoteData {
  double weight;
  double easeFactor;
  int consecutiveCorrect;
  int timesSeen;
  int timesCorrect;
  int intervalIndex;
  String? lastSeen; // ISO format timestamp
  String? nextReview; // ISO format timestamp
  bool isLearning;
  double avgResponseTimeSec;

  NoteData({
    this.weight = defaultNoteWeight,
    this.easeFactor = initialEaseFactor,
    this.consecutiveCorrect = 0,
    this.timesSeen = 0,
    this.timesCorrect = 0,
    this.intervalIndex = 0,
    this.lastSeen,
    this.nextReview,
    this.isLearning = true,
    this.avgResponseTimeSec = 0,
  });

  Map<String, dynamic> toJson() => {
        'weight': weight,
        'ease_factor': easeFactor,
        'consecutive_correct': consecutiveCorrect,
        'times_seen': timesSeen,
        'times_correct': timesCorrect,
        'interval_index': intervalIndex,
        'last_seen': lastSeen,
        'next_review': nextReview,
        'is_learning': isLearning,
        'avg_response_time_sec': avgResponseTimeSec,
      };

  factory NoteData.fromJson(Map<String, dynamic> data) {
    return NoteData(
      weight: _safeDouble(
        data['weight'],
        defaultNoteWeight,
        minVal: minNoteWeight,
        maxVal: maxNoteWeight,
      ),
      easeFactor: _safeDouble(
        data['ease_factor'],
        initialEaseFactor,
        minVal: minEaseFactor,
        maxVal: maxEaseFactor,
      ),
      consecutiveCorrect: _safeInt(data['consecutive_correct'], 0, minVal: 0),
      timesSeen: _safeInt(data['times_seen'], 0, minVal: 0),
      timesCorrect: _safeInt(data['times_correct'], 0, minVal: 0),
      intervalIndex: _safeInt(
        data['interval_index'],
        0,
        minVal: 0,
        maxVal: reviewIntervals.length - 1,
      ),
      lastSeen: _safeString(data['last_seen']),
      nextReview: _safeString(data['next_review']),
      isLearning: data['is_learning'] is bool ? data['is_learning'] as bool : true,
      avgResponseTimeSec: _safeDouble(data['avg_response_time_sec'], 0, minVal: 0),
    );
  }

  static double _safeDouble(
    dynamic value,
    double defaultValue, {
    double? minVal,
    double? maxVal,
  }) {
    double result;
    if (value is num) {
      result = value.toDouble();
    } else if (value is String) {
      result = double.tryParse(value) ?? defaultValue;
    } else {
      return defaultValue;
    }
    if (minVal != null) result = max(minVal, result);
    if (maxVal != null) result = min(maxVal, result);
    return result;
  }

  static int _safeInt(
    dynamic value,
    int defaultValue, {
    int? minVal,
    int? maxVal,
  }) {
    int result;
    if (value is int) {
      result = value;
    } else if (value is num) {
      result = value.toInt();
    } else if (value is String) {
      result = int.tryParse(value) ?? defaultValue;
    } else {
      return defaultValue;
    }
    if (minVal != null) result = max(minVal, result);
    if (maxVal != null) result = min(maxVal, result);
    return result;
  }

  static String? _safeString(dynamic value) {
    if (value == null || value == '') return null;
    return value.toString();
  }

  NoteData copyWith({
    double? weight,
    double? easeFactor,
    int? consecutiveCorrect,
    int? timesSeen,
    int? timesCorrect,
    int? intervalIndex,
    String? lastSeen,
    String? nextReview,
    bool? isLearning,
    double? avgResponseTimeSec,
  }) {
    return NoteData(
      weight: weight ?? this.weight,
      easeFactor: easeFactor ?? this.easeFactor,
      consecutiveCorrect: consecutiveCorrect ?? this.consecutiveCorrect,
      timesSeen: timesSeen ?? this.timesSeen,
      timesCorrect: timesCorrect ?? this.timesCorrect,
      intervalIndex: intervalIndex ?? this.intervalIndex,
      lastSeen: lastSeen ?? this.lastSeen,
      nextReview: nextReview ?? this.nextReview,
      isLearning: isLearning ?? this.isLearning,
      avgResponseTimeSec: avgResponseTimeSec ?? this.avgResponseTimeSec,
    );
  }
}
