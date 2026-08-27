import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../controllers/ticket_service.dart';

class QrDisplayPage extends StatefulWidget {
  const QrDisplayPage({super.key});

  @override
  State<QrDisplayPage> createState() => _QrDisplayPageState();
}

class _QrDisplayPageState extends State<QrDisplayPage> {
  String? _ticketId;
  Stream<Map<String, dynamic>?>? _ticketStream;

  @override
  void initState() {
    super.initState();
    _newTicket();
  }

 Future<void> _newTicket() async {
  try {
    print('🚀 _newTicket started');

    final id = await TicketService.createTicket();

    print('🎫 Got ticket ID: $id');

    if (!mounted) return;

    setState(() {
      _ticketId = id;
      _ticketStream = TicketService.watchTicket(id);
    });

    print('✅ QR should now display');
  } catch (e) {
    print('❌ _newTicket ERROR: $e');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to create ticket: $e'),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Show your pass')),
      body: Center(
        child: _ticketId == null
            ? const CircularProgressIndicator()
            : StreamBuilder<Map<String, dynamic>?>(
                stream: _ticketStream,
                builder: (context, snapshot) {
                  final row = snapshot.data;
                  final redeemed = row?['redeemed'] == true;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedOpacity(
                        opacity: redeemed ? 0.4 : 1.0,
                        duration: const Duration(milliseconds: 400),
                        child: ColorFiltered(
                          colorFilter: redeemed
                              ? const ColorFilter.matrix(<double>[
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0, 0, 0, 1, 0,
                                ])
                              : const ColorFilter.mode(
                                  Colors.transparent, BlendMode.multiply),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: QrImageView(
                              data: _ticketId!,
                              size: 220,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        redeemed ? 'REDEEMED' : 'Ready to scan',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: redeemed ? Colors.grey : Colors.pinkAccent,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: _newTicket,
                        child: const Text('New ticket'),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}