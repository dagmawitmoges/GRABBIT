import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/customer_notification.dart';
import '../service/notifications_service.dart';

final notificationsServiceProvider =
    Provider<NotificationsService>((ref) => NotificationsService());

class NotificationsListNotifier
    extends StateNotifier<AsyncValue<List<CustomerNotification>>> {
  final NotificationsService _svc;

  NotificationsListNotifier(this._svc) : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _svc.listMine());
  }

  Future<void> markRead(String id) async {
    await _svc.markRead(id);
    await refresh();
  }

  Future<void> markAllRead() async {
    await _svc.markAllRead();
    await refresh();
  }
}

final notificationsListProvider = StateNotifierProvider<
    NotificationsListNotifier, AsyncValue<List<CustomerNotification>>>(
  (ref) => NotificationsListNotifier(ref.watch(notificationsServiceProvider)),
);

final unreadNotificationCountProvider = Provider<int>((ref) {
  final async = ref.watch(notificationsListProvider);
  return async.maybeWhen(
    data: (list) => list.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});
