import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/db_service.dart';

class RequestModScreen extends StatefulWidget {
  const RequestModScreen({super.key});

  @override
  State<RequestModScreen> createState() => _RequestModScreenState();
}

class _RequestModScreenState extends State<RequestModScreen> {
  final _formKey = GlobalKey<FormState>();
  final _modNameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final db = Provider.of<DBService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request a Mod'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _modNameController,
                decoration: const InputDecoration(labelText: 'Mod Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a mod name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final uid = auth.currentUser!.uid;
                    final username = auth.currentUser!.username;
                    final request = {
                      'uid': uid,
                      'username': username,
                      'modName': _modNameController.text,
                      'description': _descriptionController.text,
                      'status': 'pending',
                      'ts': DateTime.now().millisecondsSinceEpoch,
                    };
                    await db.createModRequest(request);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Mod request submitted!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: const Text('Submit Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
