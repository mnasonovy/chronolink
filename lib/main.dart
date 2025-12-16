/// main.dart — точка входа в приложение ChronoLink
/// Здесь инициализируется приложение, подключается Provider и тема

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/event_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const ChronoLinkApp());
}

class ChronoLinkApp extends StatelessWidget {
  const ChronoLinkApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Добавляем провайдер для управления событиями
        ChangeNotifierProvider(create: (_) => EventProvider()),
      ],
      child: MaterialApp(
        title: 'ChronoLink',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const HomeScreen(),
      ),
    );
  }
}
