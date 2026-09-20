import '../../models/mission.dart';

/// Status muat misi.
enum MissionStatus { initial, loading, loaded, error }

class MissionState {
  const MissionState({
    this.status = MissionStatus.initial,
    this.missions = const [],
    this.quizzes = const [],
    this.filteredMissions = const [],
    this.currentFilter,
    this.errorMessage,
    this.isOffline = false,
    this.lastUpdated,
  });

  final MissionStatus status;
  final List<Mission> missions; // Semua misi aktif (mobility + waste)
  final List<Mission> quizzes; // Kuis harian dari Saga
  final List<Mission> filteredMissions; // Hasil filter
  final String? currentFilter; // null = Semua, 'mobility', 'waste'
  final String? errorMessage;

  /// True bila data berasal dari cache offline.
  final bool isOffline;
  final DateTime? lastUpdated;

  /// Semua misi non-kuis (untuk tab 'Semua'). Kuis hanya lewat FAB.
  List<Mission> get allMissions => missions;

  // Sentinel agar copyWith bisa me-reset currentFilter ke null (tab 'Semua').
  // Tanpa ini, `currentFilter ?? this.currentFilter` tidak pernah bisa null
  // lagi setelah user pindah tab.
  static const _noChange = Object();

  MissionState copyWith({
    MissionStatus? status,
    List<Mission>? missions,
    List<Mission>? quizzes,
    List<Mission>? filteredMissions,
    Object? currentFilter = _noChange,
    String? errorMessage,
    bool? isOffline,
    DateTime? lastUpdated,
  }) {
    return MissionState(
      status: status ?? this.status,
      missions: missions ?? this.missions,
      quizzes: quizzes ?? this.quizzes,
      filteredMissions: filteredMissions ?? this.filteredMissions,
      currentFilter: currentFilter == _noChange
          ? this.currentFilter
          : currentFilter as String?,
      errorMessage: errorMessage,
      isOffline: isOffline ?? this.isOffline,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Filter missions berdasarkan kategori (non-kuis saja)
  List<Mission> getFiltered(String? category) {
    if (category == null) return allMissions;
    return allMissions.where((m) => m.category == category).toList();
  }
}
