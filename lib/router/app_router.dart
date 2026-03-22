import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/otp_screen.dart';
import '../features/deals/model/deal_model.dart';
import '../features/deals/screens/home_screen.dart';
import '../features/deals/screens/deal_detail_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (_, __) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (_, __) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/otp',
      builder: (context, state) {
        final email = state.extra as String;
        return OtpScreen(email: email);
      },
    ),
    GoRoute(
      path: '/home',
      builder: (_, __) => const HomeScreen(),
    ),
    GoRoute(
      path: '/deals/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return DealDetailScreen(dealId: id);
      },
    ),
    GoRoute(
      path: '/orders',
      builder: (_, __) => const Scaffold(
        body: Center(child: Text('Orders — Module 4')),
      ),
    ),
    GoRoute(
      path: '/orders/new',
      builder: (context, state) {
        final deal = state.extra as Deal;
        return Scaffold(
          body: Center(child: Text('Place Order — Module 4\n${deal.title}')),
        );
      },
    ),
    GoRoute(
      path: '/profile',
      builder: (_, __) => const Scaffold(
        body: Center(child: Text('Profile — Module 5')),
      ),
    ),
  ],
);