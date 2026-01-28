import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MonthScreen extends StatelessWidget {
  const MonthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chronolink • Month')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Month view (stub)'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.go('/week'),
              child: const Text('Go to Week'),
            ),
            ElevatedButton(
              onPressed: () => context.go('/day'),
              child: const Text('Go to Day'),
            ),
          ],
        ),
      ),
    );
  }
}
