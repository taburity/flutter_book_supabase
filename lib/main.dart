import "dart:io";
import "package:flutter/material.dart";
import "package:path_provider/path_provider.dart";
import 'package:supabase_flutter/supabase_flutter.dart';
import "auth_screen.dart";
import "flutter_book_home_screen.dart";
import "utils.dart" as utils;

const supabaseUrl = 'https://clamrjltapuzstnaiyhf.supabase.co';
const supabaseKey = String.fromEnvironment('SUPABASE_KEY');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print("## main(): FlutterBook Starting");
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  await startMeUp();
}

Future<void> startMeUp() async {
  Directory docsDir = await getApplicationDocumentsDirectory();
  utils.docsDir = docsDir;
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlutterBook',
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          final session = Supabase.instance.client.auth.currentSession;
          //se não está logado, mostra a tela de autenticação
          if (session == null) {
            return AuthScreen();
          } else { //se está logado, verifica se existe perfil
            return FutureBuilder(
              future: _ensureProfile(session),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                else return FlutterBookHomeScreen();
              },
            );
          }
        },
      ),
    );
  }

  Future<void> _ensureProfile(Session session) async {
    final supabase = Supabase.instance.client;
    final userId = session.user.id;

    final profile = await supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (profile == null && utils.pendingFullName != null) {
      await supabase.from('profiles').insert({
        'id': userId,
        'full_name': utils.pendingFullName,
      });

      // Limpa o nome após uso
      utils.pendingFullName = null;
    }
  }
}