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
  });

  final MissionStatus status;
  final List<Mission> missions;       // Semua misi aktif (mobility + waste)
  final List<Mission> quizzes;        // Kuis harian dari Saga
  final List<Mission> filteredMissions; // Hasil filter
  final String? currentFilter;        // null = Semua, 'mobility', 'waste', 'quiz'
  final String? errorMessage;

  /// Gabungan semua misi (untuk tab 'Semua')
  List<Mission> get allMissions => [...missions, ...quizzes];

  MissionState copyWith({
    MissionStatus? status,
    List<Mission>? missions,
    List<Mission>? quizzes,
    List<Mission>? filteredMissions,
    String? currentFilter,
    String? errorMessage,
  }) {
    return MissionState(
      status: status ?? this.status,
      missions: missions ?? this.missions,
      quizzes: quizzes ?? this.quizzes,
      filteredMissions: filteredMissions ?? this.filteredMissions,
      currentFilter: currentFilter ?? this.currentFilter,
      errorMessage: errorMessage,
    );
  }

  /// Filter missions berdasarkan kategori
  List<Mission> getFiltered(String? category) {
    if (category == null) return allMissions;
    if (category == 'quiz') return quizzes;
    return allMissions.where((m) => m.category == category).toList();
  }
}