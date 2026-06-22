import 'package:flutter/material.dart';
import 'package:student_management/screens/login_screen.dart';
import 'package:student_management/screens/home_screen.dart';
import 'package:student_management/services/api_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Saby Track',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1D7C3E)),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<bool> _session = ApiService().restoreSession();

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    future: _session,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(
          backgroundColor: Color(0xFF1D7C3E),
          body: Center(child: CircularProgressIndicator(color: Colors.white)),
        );
      }
      return snapshot.data == true ? const HomeScreen() : const LoginScreen();
    },
  );
}
