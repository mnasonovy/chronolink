import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WeekScreen extends StatelessWidget {
  const WeekScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chronolink • Week')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Week view (stub)'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.go('/month'),
              child: const Text('Go to Month'),
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
