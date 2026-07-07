import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: FeishinApp()));
}

class FeishinApp extends StatelessWidget {
  const FeishinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Feishin',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Phase 0 placeholder — replaced by go_router + real auth/library
      // screens in phases 1-3 (see plan: dazzling-churning-treasure.md).
      home: const Scaffold(body: Center(child: Text('Feishin'))),
    );
  }
}
