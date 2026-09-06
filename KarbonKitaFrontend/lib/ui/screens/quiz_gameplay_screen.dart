import 'dart:async';

import 'package:flutter/material.dart';
import '../../models/quiz_question.dart';
import '../../models/quiz_stage.dart';
import '../widgets/quiz/quiz_answer_option.dart';
import '../widgets/quiz/quiz_feedback_card.dart';
import '../widgets/quiz/quiz_gameplay_header.dart';

/// Halaman gameplay kuis interaktif Babak 3.
/// Timer per babak, jawaban tersimpan per soal, koreksi di akhir.
class QuizGameplayScreen extends StatefulWidget {
  final QuizStage stage;

  const QuizGameplayScreen({super.key, required this.stage});

  @override
  State<QuizGameplayScreen> createState() => _QuizGameplayScreenState();
}

class _QuizGameplayScreenState extends State<QuizGameplayScreen> {
  static const int _totalSeconds = QuizBabak3Data.babakDurationSeconds;

  int _currentIndex = 0;
  final Map<int, int> _answers = {};
  int _remainingSeconds = _totalSeconds;
  Timer? _timer;
  bool _timeUp = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() => _timeUp = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Waktu habis! Jawaban terkunci.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  QuizQuestion get _question => QuizBabak3Data.questions[_currentIndex];
  bool get _isLast => _currentIndex == QuizBabak3Data.questions.length - 1;
  int? get _selected => _answers[_currentIndex];

  void _select(int optionIndex) {
    if (_timeUp) return;
    setState(() => _answers[_currentIndex] = optionIndex);
  }

  void _next() {
    if (_isLast) {
      var score = 0;
      for (var i = 0; i < QuizBabak3Data.questions.length; i++) {
        if (_answers[i] == QuizBabak3Data.questions[i].correctIndex) score++;
      }
      // TODO: ganti dengan halaman hasil kuis saat sudah tersedia.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Babak selesai! Skor kamu $score dari ${QuizBabak3Data.questions.length} benar.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _currentIndex++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: QuizGameplayHeader(
                    title: QuizBabak3Data.title,
                    currentIndex: _currentIndex,
                    total: QuizBabak3Data.questions.length,
                    answeredCount: _answers.length,
                    remainingSeconds: _remainingSeconds,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(child: _buildQuestionCard()),
                _buildBottomBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    return SingleChildScrollView(
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
                    _question.question,
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
            ...List.generate(_question.options.length, (i) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: i == _question.options.length - 1 ? 0 : 10,
                ),
                child: QuizAnswerOptionTile(
                  option: _question.options[i],
                  selected: _selected == i,
                  locked: _timeUp,
                  onTap: () => _select(i),
                ),
              );
            }),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _selected == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: QuizFeedbackCard(
                        key: ValueKey('feedback_$_currentIndex'),
                        explanation: _question.explanation,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
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
          onPressed: _next,
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
              Text(
                _isLast ? 'Selesaikan' : 'Soal Berikutnya',
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
