import '../../models/level_tier.dart';

/// Status muat level tiers.
enum LevelStatus { initial, loading, loaded, error }

class LevelState {
  const LevelState({
    this.status = LevelStatus.initial,
    this.data,
    this.errorMessage,
    this.isUnauthorized = false,
  });

  final LevelStatus status;
  final LevelTiersData? data;
  final String? errorMessage;

  /// True bila backend 401 — UI harus logout, bukan sekadar retry.
  final bool isUnauthorized;

  LevelState copyWith({
    LevelStatus? status,
    LevelTiersData? data,
    String? errorMessage,
    bool? isUnauthorized,
  }) {
    return LevelState(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage,
      isUnauthorized: isUnauthorized ?? this.isUnauthorized,
    );
  }
}
