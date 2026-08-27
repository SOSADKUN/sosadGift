import 'package:supabase_flutter/supabase_flutter.dart';

class TicketService {
  static SupabaseClient get _client => Supabase.instance.client;

  static Future<String> createTicket() async {
    try {
      print('🎫 Creating ticket...');

      final response = await _client
          .from('tickets')
          .insert({})
          .select('id')
          .single();

      print('✅ Ticket created: $response');

      return response['id'] as String;
    } catch (e, stackTrace) {
      print('❌ createTicket ERROR: $e');
      print(stackTrace);
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> redeemTicket(
    String ticketId,
  ) async {
    try {
      final response = await _client
          .from('tickets')
          .update({
            'redeemed': true,
            'redeemed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', ticketId)
          .eq('redeemed', false)
          .select()
          .maybeSingle();

      return response;
    } catch (e, stackTrace) {
      print('❌ redeemTicket ERROR: $e');
      print(stackTrace);
      rethrow;
    }
  }

  static Stream<Map<String, dynamic>?> watchTicket(String ticketId) {
    return _client
        .from('tickets')
        .stream(primaryKey: ['id'])
        .eq('id', ticketId)
        .map((rows) {
          print('📡 Ticket stream: $rows');
          return rows.isEmpty ? null : rows.first;
        });
  }
}