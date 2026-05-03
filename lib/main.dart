import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/env.dart';
import 'core/constants/app_theme.dart';
import 'features/auth/provider/auth_provider.dart';
import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env.development');
  // Only keys from .env may call [initialize] once; do not use [Env.hasSupabase] here
  // (it becomes true after init and would break hot restart).
  if (Env.supabaseUrl != null && Env.supabaseAnonKey != null) {
    await Supabase.initialize(
      url: Env.supabaseUrl!,
      anonKey: Env.supabaseAnonKey!,
    );
  }
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