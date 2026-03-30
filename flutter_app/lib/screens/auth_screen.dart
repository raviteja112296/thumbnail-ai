import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    final auth = context.read<AuthService>();
    final err = _isLogin
        ? await auth.login(_emailCtrl.text.trim(), _passCtrl.text.trim())
        : await auth.register(_emailCtrl.text.trim(), _passCtrl.text.trim());
    if (mounted) setState(() { _loading = false; _error = err; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Thumbnail AI',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(_isLogin ? 'Welcome back!' : 'Create your account',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center),
              const SizedBox(height: 40),
              TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              TextField(
                controller: _passCtrl,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder()),
                obscureText: true),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red))],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF6C63FF)),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_isLogin ? 'Login' : 'Register',
                        style: const TextStyle(fontSize: 16, color: Colors.white))),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(_isLogin
                    ? "Don't have an account? Register"
                    : 'Already have an account? Login')),
            ],
          ),
        ),
      ),
    );
  }
}