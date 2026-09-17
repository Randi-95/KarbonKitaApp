import '../../models/dashboard.dart';

/// Status muat dashboard Beranda.
enum DashboardStatus { initial, loading, loaded, error }

class DashboardState {
  const DashboardState({
    this.status = DashboardStatus.initial,
    this.dashboard,
    this.errorMessage,
    this.isUnauthorized = false,
  });

  final DashboardStatus status;
  final DashboardData? dashboard;
  final String? errorMessage;

  /// True bila backend 401 — UI harus logout, bukan sekadar retry.
  final bool isUnauthorized;

  DashboardState copyWith({
    DashboardStatus? status,
    DashboardData? dashboard,
    String? errorMessage,
    bool? isUnauthorized,
  }) {
    return DashboardState(
      status: status ?? this.status,
      dashboard: dashboard ?? this.dashboard,
      errorMessage: errorMessage,
      isUnauthorized: isUnauthorized ?? this.isUnauthorized,
    );
  }
}
