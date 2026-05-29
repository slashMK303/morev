import 'package:flutter/material.dart';
import 'package:morev/screens/login_screen.dart';
import 'package:morev/theme/app_theme.dart';
import 'package:morev/state/app_state.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppState _appState = AppState();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Morev Movie Review',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: LoginScreen(appState: _appState),
    );
  }
}
