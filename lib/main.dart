import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Khởi chạy ứng dụng bọc trong ProviderScope của Riverpod 2 (Slide 10 & 14 VKU Week 8)
  runApp(
    const ProviderScope(
      child: ExpenseTrackerApp(),
    ),
  );
}

/// Ứng dụng chính tuân thủ Material Design 3, VKU Navy Brand Color (Slide 32)
/// Kết nối Declarative Routing với MaterialApp.router(routerConfig: appRouter) (Slide 21 VKU Week 8)
class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF2C4570); // VKU Navy

    return MaterialApp.router(
      title: 'VKU Expense & Income Tracker',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter, // GoRouter config (Slide 21)

      // Theme Sáng (Light Theme Material 3)
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),

      // Theme Tối (Dark Theme Material 3 - Rubric Slide 42 UI/UX Polish)
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),

      themeMode: ThemeMode.system, // Tự động thích ứng Light/Dark mode
    );
  }
}
