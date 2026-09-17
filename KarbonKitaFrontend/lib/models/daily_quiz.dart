import 'mission.dart';
import 'quiz_question.dart';

/// Kuis harian dari `GET /api/saga/quizzes` (1 soal per hari).
/// Backend QuizResource: id, mission_id, mission_title, question, options,
/// order, is_completed_today, xp_reward (+correct_answer/explanation
/// hanya bila sudah selesai hari ini).
class DailyQuiz {
  const DailyQuiz({
    required this.id,
    required this.missionId,
    required this.missionTitle,
    required this.question,
    required this.options,
    required this.order,
    required this.isCompletedToday,
    required this.xpReward,
    required this.correctAnswer,
    required this.explanation,
  });

  final int id;
  final int missionId;
  final String missionTitle;
  final String question;
  final List<QuizAnswerOption> options;
  final int order;
  final bool isCompletedToday;
  final int xpReward;

  /// Kunci jawaban (A/B/C/D) — hanya ada bila sudah selesai hari ini.
  final String? correctAnswer;

  /// Pembahasan — hanya ada bila sudah selesai hari ini.
  final String? explanation;

  factory DailyQuiz.fromJson(Map<String, dynamic> json) {
    return DailyQuiz(
      id: _toInt(json['id']),
      missionId: _toInt(json['mission_id']),
      missionTitle: json['mission_title'] as String? ?? 'Kuis Harian',
      question: json['question'] as String? ?? '',
      options: _parseOptions(json['options']),
      order: _toInt(json['order']),
      isCompletedToday: json['is_completed_today'] as bool? ?? false,
      xpReward: _toInt(json['xp_reward']),
      correctAnswer: (json['correct_answer'] as String?)?.toUpperCase(),
      explanation: json['explanation'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'mission_id': missionId,
    'mission_title': missionTitle,
    'question': question,
    'options': {for (final o in options) o.label: o.text},
    'order': order,
    'is_completed_today': isCompletedToday,
    'xp_reward': xpReward,
    'correct_answer': correctAnswer,
    'explanation': explanation,
  };

  /// Representasi ringkas untuk daftar misi (tab Misi).
  Mission toMission() {
    return Mission(
      id: missionId,
      title: missionTitle,
      description: question,
      category: 'quiz',
      xpReward: xpReward,
      pointsReward: 0,
      icon: '',
    );
  }
}

/// Hasil `POST /api/saga/answer`.
class QuizAnswerResult {
  const QuizAnswerResult({
    required this.isCorrect,
    required this.xpEarned,
    required this.newXp,
    required this.newLevel,
    required this.streakDays,
    required this.attemptsToday,
    required this.userMissionId,
  });

  final bool isCorrect;
  final int xpEarned;
  final int newXp;
  final String newLevel;
  final int streakDays;
  final int attemptsToday;
  final int userMissionId;

  factory QuizAnswerResult.fromJson(Map<String, dynamic> json) {
    return QuizAnswerResult(
      isCorrect: json['is_correct'] as bool? ?? false,
      xpEarned: _toInt(json['xp_earned']),
      newXp: _toInt(json['new_xp']),
      newLevel: json['new_level'] as String? ?? '',
      streakDays: _toInt(json['streak_days']),
      attemptsToday: _toInt(json['attempts_today']),
      userMissionId: _toInt(json['user_mission_id']),
    );
  }

  Map<String, dynamic> toJson() => {
    'is_correct': isCorrect,
    'xp_earned': xpEarned,
    'new_xp': newXp,
    'new_level': newLevel,
    'streak_days': streakDays,
    'attempts_today': attemptsToday,
    'user_mission_id': userMissionId,
  };
}

/// Backend mengirim options sebagai Map dari label ke teks.
/// Tahan juga bentuk List of Maps dan List of String untuk jaga-jaga.
List<QuizAnswerOption> _parseOptions(dynamic raw) {
  if (raw is Map) {
    final entries = raw.entries.toList()
      ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));
    return [
      for (final e in entries)
        QuizAnswerOption(
          label: e.key.toString().toUpperCase(),
          text: e.value?.toString() ?? '',
        ),
    ];
  }
  if (raw is List) {
    const labels = ['A', 'B', 'C', 'D', 'E', 'F'];
    return [
      for (var i = 0; i < raw.length; i++)
        if (raw[i] is Map<String, dynamic>)
          QuizAnswerOption(
            label:
                (raw[i]['label'] as String?)?.toUpperCase() ??
                (i < labels.length ? labels[i] : '${i + 1}'),
            text: raw[i]['text']?.toString() ?? '',
          )
        else
          QuizAnswerOption(
            label: i < labels.length ? labels[i] : '${i + 1}',
            text: raw[i]?.toString() ?? '',
          ),
    ];
  }
  return const [];
}

int _toInt(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
