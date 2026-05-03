import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_theme.dart';
import '../provider/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsListProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(notificationsListProvider.notifier).markAllRead();
            },
            child: Text(
              'Mark all read',
              style: GoogleFonts.poppins(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load notifications.\n$e',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: AppTheme.textMedium),
            ),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded,
                      size: 64, color: AppTheme.textLight.withValues(alpha: 0.6)),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We’ll let you know about orders and updates here.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.textMedium,
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            color: AppTheme.primary,
            onRefresh: () =>
                ref.read(notificationsListProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final n = items[i];
                return Material(
                  color: AppTheme.surface,
                  elevation: n.isRead ? 0 : 0.5,
                  shadowColor: Colors.black12,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () {
                      if (!n.isRead) {
                        ref
                            .read(notificationsListProvider.notifier)
                            .markRead(n.id);
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: n.isRead
                              ? AppTheme.divider
                              : AppTheme.primary.withValues(alpha: 0.35),
                        ),
                        color: n.isRead
                            ? AppTheme.surface
                            : AppTheme.primary.withValues(alpha: 0.06),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  n.title ?? 'Update',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                              ),
                              if (!n.isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          if (n.message != null &&
                              n.message!.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              n.message!,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                height: 1.4,
                                color: AppTheme.textMedium,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            n.createdAt.length > 16
                                ? n.createdAt.substring(0, 16)
                                : n.createdAt,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppTheme.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
