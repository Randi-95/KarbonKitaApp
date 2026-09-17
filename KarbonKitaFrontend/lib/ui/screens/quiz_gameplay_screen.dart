import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/quiz/quiz_bloc.dart';
import '../../bloc/quiz/quiz_event.dart';
import '../../bloc/quiz/quiz_state.dart';
import '../../models/daily_quiz.dart';
import '../widgets/quiz/quiz_answer_option.dart';
import '../widgets/quiz/quiz_feedback_card.dart';

/// Halaman gameplay kuis harian: 1 soal dari backend per hari.
/// Jawab benar → +XP; salah boleh coba lagi sampai benar.
class QuizGameplayScreen extends StatefulWidget {
  final DailyQuiz quiz;

  const QuizGameplayScreen({super.key, required this.quiz});

  @override
  State<QuizGameplayScreen> createState() => _QuizGameplayScreenState();
}

class _QuizGameplayScreenState extends State<QuizGameplayScreen> {
  String? _selectedLabel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<QuizBloc>().add(const DailyQuizLoaded());
      }
    });
  }

  void _submit(DailyQuiz quiz) {
    final label = _selectedLabel;
    if (label == null) return;
    context.read<QuizBloc>().add(QuizAnswered(label));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<QuizBloc, QuizState>(
        listenWhen: (prev, curr) =>
            (!prev.isUnauthorized && curr.isUnauthorized) ||
            (prev.errorMessage != curr.errorMessage &&
                curr.errorMessage != null) ||
            prev.lastResult != curr.lastResult,
        listener: (context, state) {
          if (state.isUnauthorized) {
            context.read<AuthBloc>().add(const LoggedOut());
          } else if (state.errorMessage != null && state.lastResult == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          // Jawaban salah → buka kunci pilihan agar bisa coba lagi.
          if (state.lastResult != null && !state.lastResult!.isCorrect) {
            setState(() => _selectedLabel = null);
          }
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/backgroundkuis.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: const Color(0xFFF2F7F0)),
              ),
            ),
            SafeArea(
              child: BlocBuilder<QuizBloc, QuizState>(
                builder: (context, state) {
                  // Pakai kuis terbaru dari bloc bila ada, fallback ke awal.
                  final quiz = state.quiz ?? widget.quiz;
                  final isBusy = state.status == QuizStatus.answering;

                  if ((state.status == QuizStatus.loading ||
                          state.status == QuizStatus.initial) &&
                      state.quiz == null) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF43A047),
                      ),
                    );
                  }

                  if (state.status == QuizStatus.error && state.quiz == null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.cloud_off,
                              size: 48,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              state.errorMessage ?? 'Gagal memuat kuis.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => context.read<QuizBloc>().add(
                                const DailyQuizLoaded(force: true),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF43A047),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final result = state.lastResult;
                  final completed = quiz.isCompletedToday && result == null;
                  final justCorrect = result != null && result.isCorrect;
                  final locked = isBusy || completed || justCorrect;

                  // Kunci jawaban terungkap bila sudah selesai / baru benar.
                  final revealed = (completed || justCorrect)
                      ? quiz.correctAnswer
                      : null;

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: _buildHeader(quiz),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.07),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFF43A047),
                                          width: 2,
                                        ),
                                        color: const Color(0xFFE8F5E9),
                                      ),
                                      child: const Icon(
                                        Icons.eco,
                                        color: Color(0xFF43A047),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        quiz.question,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                          height: 1.45,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ...List.generate(quiz.options.length, (i) {
                                  final opt = quiz.options[i];
                                  final isRevealed =
                                      revealed != null && opt.label == revealed;
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: i == quiz.options.length - 1
                                          ? 0
                                          : 10,
                                    ),
                                    child: QuizAnswerOptionTile(
                                      option: opt,
                                      selected:
                                          isRevealed ||
                                          _selectedLabel == opt.label,
                                      locked: locked,
                                      onTap: () => setState(
                                        () => _selectedLabel = opt.label,
                                      ),
                                    ),
                                  );
                                }),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  child: _buildFeedback(
                                    quiz: quiz,
                                    completed: completed,
                                    justCorrect: justCorrect,
                                    result: result,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      _buildBottomBar(
                        quiz: quiz,
                        isBusy: isBusy,
                        completed: completed,
                        justCorrect: justCorrect,
                        hasResult: result != null,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(DailyQuiz quiz) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                quiz.missionTitle,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Text(
                'Kuis Harian • 1 soal',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.flash_on, color: Color(0xFF43A047), size: 16),
              const SizedBox(width: 4),
              Text(
                '+${quiz.xpReward} XP',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeedback({
    required DailyQuiz quiz,
    required bool completed,
    required bool justCorrect,
    required QuizAnswerResult? result,
  }) {
    if (completed) {
      if (quiz.explanation == null || quiz.explanation!.isEmpty) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: QuizFeedbackCard(
          key: const ValueKey('feedback_done'),
          variant: QuizFeedbackVariant.correct,
          title: 'Sudah Selesai Hari Ini',
          explanation: quiz.explanation!,
        ),
      );
    }
    if (justCorrect && result != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: QuizFeedbackCard(
          key: const ValueKey('feedback_correct'),
          variant: QuizFeedbackVariant.correct,
          title: 'Benar! +${result.xpEarned} XP',
          explanation: (quiz.explanation == null || quiz.explanation!.isEmpty)
              ? 'Streak dan XP-mu bertambah. Kembali besok untuk soal baru!'
              : quiz.explanation!,
        ),
      );
    }
    if (result != null && !result.isCorrect) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: QuizFeedbackCard(
          key: ValueKey('feedback_wrong_${result.attemptsToday}'),
          variant: QuizFeedbackVariant.incorrect,
          explanation:
              'Jawaban belum tepat. Pilih jawaban lain lalu kirim lagi — bisa coba sampai benar!',
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildBottomBar({
    required DailyQuiz quiz,
    required bool isBusy,
    required bool completed,
    required bool justCorrect,
    required bool hasResult,
  }) {
    final canSubmit =
        !isBusy && !completed && !justCorrect && _selectedLabel != null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: (completed || justCorrect)
              ? () => Navigator.of(context).pop()
              : canSubmit
              ? () => _submit(quiz)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isBusy)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                Text(
                  (completed || justCorrect)
                      ? 'Selesai'
                      : hasResult
                      ? 'Kirim Lagi'
                      : 'Kirim Jawaban',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
