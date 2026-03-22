import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_theme.dart';
import 'features/auth/provider/auth_provider.dart';
import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env.development');
  runApp(const ProviderScope(child: GrabbitApp()));
}

class GrabbitApp extends ConsumerWidget {
  const GrabbitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (!authState.isInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Grabbit',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
                SizedBox(height: 24),
                CircularProgressIndicator(color: AppTheme.primary),
              ],
            ),
          ),
        ),
      );
    }

    return MaterialApp.router(
      title: 'Grabbit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      routerConfig: createRouter(ref),
    );
  }
}