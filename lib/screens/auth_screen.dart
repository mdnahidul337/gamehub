import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  String _email = '';
  String _password = '';
  String _username = '';
  String? _adminCode;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Login' : 'Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Email'),
                    onSaved: (v) => _email = v?.trim() ?? '',
                    validator: (v) => (v == null || !v.contains('@'))
                        ? 'Enter valid email'
                        : null,
                  ),
                  if (!_isLogin)
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Username'),
                      onSaved: (v) => _username = v?.trim() ?? '',
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter a username'
                          : null,
                    ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    onSaved: (v) => _password = v ?? '',
                    validator: (v) =>
                        (v == null || v.length < 6) ? '6+ chars' : null,
                  ),
                  if (!_isLogin)
                    TextFormField(
                      decoration: const InputDecoration(
                          labelText: 'Admin Code (optional)'),
                      onSaved: (v) => _adminCode = v?.trim(),
                    ),
                  const SizedBox(height: 12),
                  if (_error != null)
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ElevatedButton(
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) return;
                        _formKey.currentState!.save();
                        setState(() => _error = null);
                        String? msg;
                        if (_isLogin) {
                          msg = await auth.signInWithEmail(_email, _password);
                        } else {
                          msg = await auth.registerWithEmail(
                              _email, _password, _username,
                              adminCode: _adminCode);
                        }
                        if (msg != null) {
                          setState(() => _error = msg);
                        }
                      },
                      child: Text(_isLogin ? 'Login' : 'Register')),
                  TextButton(
                      onPressed: () => setState(() => _isLogin = !_isLogin),
                      child: Text(
                          _isLogin ? 'Create account' : 'Have account? Login')),
                  if (_isLogin)
                    TextButton(
                      onPressed: _showPasswordResetDialog,
                      child: const Text('Forgot Password?'),
                    ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showPasswordResetDialog() {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your email to receive a password reset link.'),
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final auth = Provider.of<AuthService>(context, listen: false);
              final email = emailController.text.trim();
              if (email.isNotEmpty) {
                final msg = await auth.sendPasswordResetEmail(email);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(msg ?? 'Password reset email sent.')),
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
