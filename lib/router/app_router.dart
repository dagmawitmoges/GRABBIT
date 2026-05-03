import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;
import '../core/config/env.dart';
import '../features/auth/provider/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/otp_screen.dart';
import '../features/auth/screens/profile_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/welcome_screen.dart';
import '../features/deals/model/deal_model.dart';
import '../features/deals/screens/home_screen.dart';
import '../features/deals/screens/deal_detail_screen.dart';
import '../features/favorites/screens/favorites_screen.dart';
import '../features/orders/screens/orders_screen.dart';
import '../features/orders/screens/place_order_screen.dart';
import '../features/orders/screens/review_screen.dart';
import '../features/orders/model/review_route_args.dart';
import '../features/vendor/screens/vendor_reviews_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';

bool _isProtectedPath(String loc) {
  if (loc.startsWith('/home')) return true;
  if (loc.startsWith('/deals')) return true;
  if (loc.startsWith('/orders')) return true;
  if (loc.startsWith('/profile')) return true;
  if (loc.startsWith('/notifications')) return true;
  if (loc.startsWith('/favorites')) return true;
  if (loc.startsWith('/vendor')) return true;
  return false;
}

GoRouter createRouter(WidgetRef ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/welcome',
    redirect: (context, state) {
      if (!authState.isInitialized) return null;

      final loc = state.matchedLocation;
      final user = authState.user;

      // Profile row can lag behind auth.users; still allow OTP if we have a session.
      if (Env.hasSupabase &&
          loc == '/otp' &&
          user == null &&
          Supabase.instance.client.auth.currentSession == null) {
        return '/welcome';
      }

      if (user != null && !user.isVerified) {
        if (loc == '/otp' || loc == '/register') return null;
        return '/otp';
      }

      final loggedIn = authState.isFullyAuthenticated;
      const authShell = {
        '/welcome',
        '/login',
        '/register',
        '/otp',
      };

      if (!loggedIn && _isProtectedPath(loc)) {
        return '/welcome';
      }

      if (loggedIn && authShell.contains(loc)) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (_, __) => const WelcomeScreen(),
      ),
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
          final extra = state.extra as String?;
          return OtpScreen(recipientOverride: extra);
        },
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: '/favorites',
        builder: (_, __) => const FavoritesScreen(),
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
        builder: (_, __) => const OrdersScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) {
              final deal = state.extra as Deal;
              return PlaceOrderScreen(deal: deal);
            },
          ),
          GoRoute(
            path: ':id/review',
            builder: (context, state) {
              final orderId = state.pathParameters['id']!;
              final extra = state.extra;
              if (extra is ReviewRouteArgs) {
                return ReviewScreen.fromArgs(extra);
              }
              return ReviewScreen(
                orderId: orderId,
                dealId: '',
                dealTitle: extra is String ? extra : 'Deal',
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/vendor/:userId/reviews',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return VendorReviewsScreen(vendorUserId: userId);
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),
    ],
  );
}
