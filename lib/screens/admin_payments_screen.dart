import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/db_service.dart';

class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  _AdminPaymentsScreenState createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> {
  late Future<List<Map<String, dynamic>>> _paymentsFuture;

  @override
  void initState() {
    super.initState();
    _paymentsFuture = _fetchPayments();
  }

  Future<List<Map<String, dynamic>>> _fetchPayments() {
    // This is a placeholder. A real implementation would fetch from a 'payments' collection.
    // For now, we'll simulate with recent purchases.
    return Provider.of<DBService>(context, listen: false)
        .listRecentPurchases();
  }

  void _refresh() {
    setState(() {
      _paymentsFuture = _fetchPayments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DBService>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Payment Status'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _paymentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No pending payments.'));
          }
          final payments = snapshot.data!;
          return ListView.builder(
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              return ListTile(
                title: Text('User ID: ${payment['uid']}'),
                subtitle: Text('Mod ID: ${payment['modId']}'),
                trailing: payment['status'] == 'pending'
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () async {
                              await db.approvePayment(
                                  payment['id'],
                                  payment['uid'],
                                  payment['price']);
                              _refresh();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () async {
                              await db.rejectPayment(payment['id']);
                              _refresh();
                            },
                          ),
                        ],
                      )
                    : Text(payment['status']),
              );
            },
          );
        },
      ),
    );
  }
}
