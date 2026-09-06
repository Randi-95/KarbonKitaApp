import 'package:flutter/material.dart';

/// Indikator progres bertingkat: hijau = sudah dilewati/aktif, abu = belum.
class QuizProgressSegments extends StatelessWidget {
  final int total;
  final int answeredCount;
  final int currentIndex;

  const QuizProgressSegments({
    super.key,
    required this.total,
    required this.answeredCount,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isDone = i < answeredCount || i == currentIndex;
        return Expanded(
          child: Container(
            height: 6,
            margin: EdgeInsets.only(
              left: i == 0 ? 0 : 3,
              right: i == total - 1 ? 0 : 3,
            ),
            decoration: BoxDecoration(
              color: isDone
                  ? const Color(0xFF43A047)
                  : const Color(0xFFBDBDBD).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}
