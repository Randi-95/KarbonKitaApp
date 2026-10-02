import '../../models/mission.dart';

/// Status muat misi.
enum MissionStatus { initial, loading, loaded, error }

/// Status sinkronisasi mobilitas (terpisah dari status daftar misi).
enum MobilitySyncStatus { initial, syncing, success, failure }

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
    this.mobilityStatus = MobilitySyncStatus.initial,
    this.mobilityResult,
    this.mobilityErrorMessage,
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

  /// Hasil sync mobilitas terakhir (isi `data` dari envelope backend).
  final MobilitySyncStatus mobilityStatus;
  final Map<String, dynamic>? mobilityResult;
  final String? mobilityErrorMessage;

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
    MobilitySyncStatus? mobilityStatus,
    Object? mobilityResult = _noChange,
    Object? mobilityErrorMessage = _noChange,
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
      mobilityStatus: mobilityStatus ?? this.mobilityStatus,
      mobilityResult: mobilityResult == _noChange
          ? this.mobilityResult
          : mobilityResult as Map<String, dynamic>?,
      mobilityErrorMessage: mobilityErrorMessage == _noChange
          ? this.mobilityErrorMessage
          : mobilityErrorMessage as String?,
    );
  }

  /// Filter missions berdasarkan kategori (non-kuis saja)
  List<Mission> getFiltered(String? category) {
    if (category == null) return allMissions;
    return allMissions.where((m) => m.category == category).toList();
  }
}
