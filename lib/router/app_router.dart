import 'package:go_router/go_router.dart';
import 'package:grabbit/features/auth/screens/profile_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/otp_screen.dart';
import '../features/deals/model/deal_model.dart';
import '../features/deals/screens/home_screen.dart';
import '../features/deals/screens/deal_detail_screen.dart';
import '../features/orders/screens/orders_screen.dart';
import '../features/orders/screens/place_order_screen.dart';
import '../features/orders/screens/review_screen.dart';

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
            final dealTitle = state.extra as String;
            return ReviewScreen(
              orderId: orderId,
              dealTitle: dealTitle,
            );
          },
        ),
      ],
    ),
    GoRoute(
  path: '/profile',
  builder: (_, __) => const ProfileScreen(),
),
  ],
);