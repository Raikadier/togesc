import 'package:supabase_flutter/supabase_flutter.dart';

const String deleteOwnAccountRpc = 'delete_own_account';

/// Operaciones de cuenta en Supabase (Fase 7E-1).
abstract final class AccountService {
  /// Borra el usuario de Auth y su fila en user_progress (cascade).
  static Future<void> deleteOwnAccount(SupabaseClient client) async {
    await client.rpc(deleteOwnAccountRpc);
    await client.auth.signOut();
  }
}
