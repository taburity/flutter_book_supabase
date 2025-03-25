import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import "utils.dart" as utils;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;

  Future<void> _authenticate() async {
    setState(() => _loading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final fullName = _nameController.text.trim();
    final supabase = Supabase.instance.client;

    try {
      if (_isLogin) {
        await supabase.auth.signInWithPassword(email: email, password: password);
      } else {
        final response = await supabase.auth.signUp(
          email: email,
          password: password,
        );

        final user = response.user;
        if (user != null) {
          utils.pendingFullName = fullName; // Salva temporariamente o nome
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign-up successful. Please check your email.')),
        );
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Login' : 'Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          if (!_isLogin)
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
          ),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loading ? null : _authenticate,
            child: Text(_isLogin ? 'Login' : 'Sign Up'),
          ),
          TextButton(
            onPressed: () => setState(() => _isLogin = !_isLogin),
            child: Text(_isLogin
                ? 'Don\'t have an account? Sign up'
                : 'Already have an account? Log in'),
          )
        ]),
      ),
    );
  }
}