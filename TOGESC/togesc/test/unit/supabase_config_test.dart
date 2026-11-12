import 'package:flutter_test/flutter_test.dart';

import 'package:togesc/config/supabase_config.dart';

void main() {
  test('en web los enlaces de Auth vuelven al mismo origen', () {
    expect(
      SupabaseConfig.authRedirect(
        isWeb: true,
        base: Uri.parse('https://togesc.vercel.app/#/account'),
      ),
      'https://togesc.vercel.app',
    );
  });

  test('fuera de web vuelven a la app por su esquema y no lanzan', () {
    // `Uri.base` en Android/iOS es file:///, cuyo `origin` lanzaba.
    expect(() => Uri.parse('file:///').origin, throwsStateError);
    expect(
      SupabaseConfig.authRedirect(isWeb: false, base: Uri.parse('file:///')),
      SupabaseConfig.mobileAuthRedirect,
    );
  });
}
