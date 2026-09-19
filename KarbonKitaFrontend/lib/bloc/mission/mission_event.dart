/// Event MissionBloc.
sealed class MissionEvent {
  const MissionEvent();
}

/// Muat misi aktif (mobility & waste) dari backend.
class MissionsLoaded extends MissionEvent {
  const MissionsLoaded();
}

/// Muat kuis harian (Saga Map) dari backend.
class QuizzesLoaded extends MissionEvent {
  const QuizzesLoaded();
}

/// Filter misi berdasarkan kategori.
class MissionsFiltered extends MissionEvent {
  const MissionsFiltered(this.category);

  final String? category; // null = 'Semua', 'mobility', 'waste'
}

/// Sinkronisasi aktivitas mobilitas.
class MobilitySynced extends MissionEvent {
  const MobilitySynced({
    required this.missionId,
    required this.activityType,
    required this.distanceKm,
    required this.durationSeconds,
    required this.gpsCoordinatesPath,
  });

  final int missionId;
  final String activityType;
  final double distanceKm;
  final int durationSeconds;
  final List<Map<String, double>> gpsCoordinatesPath;
}

/// Submit jawaban kuis.
class QuizAnswerSubmitted extends MissionEvent {
  const QuizAnswerSubmitted({required this.quizId, required this.answer});

  final int quizId;
  final String answer;
}
