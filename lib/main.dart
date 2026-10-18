import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'views/screens/ai_advisor_screen.dart';
import 'views/screens/expense_home_screen.dart';
import 'views/screens/reports_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Khởi chạy ứng dụng bọc trong ProviderScope của Riverpod 2 (Slide 42)
  runApp(
    const ProviderScope(
      child: ExpenseTrackerApp(),
    ),
  );
}

/// Ứng dụng chính tuân thủ Material Design 3 và VKU Navy Brand Color (Slide 32 VKU)
class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF2C4570); // VKU Navy

    return MaterialApp(
      title: 'VKU Expense OCR & AI Tracker',
      debugShowCheckedModeBanner: false,

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

      themeMode: ThemeMode.system, // Tự động thích ứng theo chế độ máy

      home: const MainNavigationShell(),
    );
  }
}

/// Shell chứa thanh NavigationBar 3 tab chính (Slide 33 & 34 Scaffold Structure)
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ExpenseHomeScreen(),
    ReportsScreen(),
    AiAdvisorScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Giữ trạng thái các tab không bị rebuild liên tục
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Chi tiêu',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'Báo cáo',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Gemini AI',
          ),
        ],
      ),
    );
  }
}
