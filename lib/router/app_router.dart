import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../views/screens/ai_advisor_screen.dart';
import '../views/screens/expense_detail_screen.dart';
import '../views/screens/expense_home_screen.dart';
import '../views/screens/reports_screen.dart';

/// Cấu hình Declarative Routing với GoRouter theo đúng chuẩn Slide 19-24 VKU Week 8
/// Hỗ trợ ShellRoute (Slide 23), Deep Linking, Path Parameters (Slide 21)
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // ShellRoute giữ thanh NavigationBar cố định khi chuyển tab (Slide 23)
    ShellRoute(
      builder: (context, state, child) {
        int currentIndex = 0;
        final location = state.matchedLocation;
        if (location.startsWith('/reports')) {
          currentIndex = 1;
        } else if (location.startsWith('/ai')) {
          currentIndex = 2;
        }

        return Scaffold(
          body: child, // Nested active tab screen
          bottomNavigationBar: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: (idx) {
              if (idx == 0) context.go('/');
              if (idx == 1) context.go('/reports');
              if (idx == 2) context.go('/ai');
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: 'Thu Chi',
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
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const ExpenseHomeScreen(),
        ),
        GoRoute(
          path: '/reports',
          builder: (context, state) => const ReportsScreen(),
        ),
        GoRoute(
          path: '/ai',
          builder: (context, state) => const AiAdvisorScreen(),
        ),
      ],
    ),

    // Dynamic Path Parameter Route `/expense/:id` (Slide 21 VKU Week 8)
    GoRoute(
      path: '/expense/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return ExpenseDetailScreen(id: id);
      },
    ),
  ],
);
