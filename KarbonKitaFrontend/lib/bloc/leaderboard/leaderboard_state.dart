import '../../models/leaderboard.dart';

/// Status muat leaderboard.
enum LeaderboardStatus { initial, loading, loaded, error }

class LeaderboardState {
  const LeaderboardState({
    this.status = LeaderboardStatus.initial,
    this.scope = LeaderboardScope.rt,
    this.timeframe = LeaderboardTimeframe.weekly,
    this.board,
    this.errorMessage,
    this.isUnauthorized = false,
  });

  final LeaderboardStatus status;
  final LeaderboardScope scope;
  final LeaderboardTimeframe timeframe;
  final LeaderboardBoard? board;
  final String? errorMessage;

  /// True bila backend 401 — UI harus logout, bukan sekadar retry.
  final bool isUnauthorized;

  LeaderboardState copyWith({
    LeaderboardStatus? status,
    LeaderboardScope? scope,
    LeaderboardTimeframe? timeframe,
    LeaderboardBoard? board,
    String? errorMessage,
    bool? isUnauthorized,
  }) {
    return LeaderboardState(
      status: status ?? this.status,
      scope: scope ?? this.scope,
      timeframe: timeframe ?? this.timeframe,
      board: board ?? this.board,
      errorMessage: errorMessage,
      isUnauthorized: isUnauthorized ?? this.isUnauthorized,
    );
  }
}
