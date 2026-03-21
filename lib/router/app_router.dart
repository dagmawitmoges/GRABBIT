import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (_, __) => const Scaffold(
        body: Center(child: Text('Login — Module 2')),
      ),
    ),
    GoRoute(
      path: '/home',
      builder: (_, __) => const Scaffold(
        body: Center(child: Text('Home — Module 3')),
      ),
    ),
  ],
);