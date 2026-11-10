import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reloj inyectable (mismo patrón que `SRSSystem(clock: ...)`).
/// En tests: `clockProvider.overrideWithValue(() => DateTime(2026, 10, 9))`.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
