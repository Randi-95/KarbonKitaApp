import 'package:flutter/material.dart';
import '../../models/quiz_stage.dart';
import '../widgets/quiz/quiz_info_card.dart';
import '../widgets/quiz/quiz_level_header.dart';
import '../widgets/quiz/quiz_path_painter.dart';
import '../widgets/quiz/quiz_stage_bottom_sheet.dart';
import '../widgets/quiz/quiz_stage_node.dart';

/// Halaman Level Kuis bergaya gamifikasi (Duolingo-like).
/// Dibuka via Floating Widget kuis (FABKuis) dengan full-screen push.
class QuizLevelScreen extends StatelessWidget {
  const QuizLevelScreen({super.key});

  QuizStage _stage(int number) =>
      QuizLevelData.stages.firstWhere((s) => s.number == number);

  void _onNodeTap(BuildContext context, QuizStage stage) {
    switch (stage.status) {
      case QuizStageStatus.active:
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => QuizStageBottomSheet(stage: stage),
        );
        break;
      case QuizStageStatus.locked:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Selesaikan ${QuizLevelData.stages.firstWhere((s) => s.status == QuizStageStatus.active, orElse: () => stage).tag} dulu untuk membuka ${stage.tag}!',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
      case QuizStageStatus.completed:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${stage.tag} sudah selesai. Kerja bagus!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F7F0),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: QuizLevelHeader(
                title: QuizLevelData.levelTitle,
                userPoints: QuizLevelData.userPoints,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    return SizedBox(
                      height: 720,
                      width: w,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(painter: QuizPathPainter()),
                          ),
                          // Panah latar dekoratif.
                          Positioned(
                            left: w * 0.16,
                            top: 150,
                            child: Icon(
                              Icons.arrow_upward,
                              size: 44,
                              color: const Color(
                                0xFF1B5E20,
                              ).withValues(alpha: 0.08),
                            ),
                          ),
                          Positioned(
                            right: w * 0.12,
                            top: 210,
                            child: Icon(
                              Icons.arrow_upward,
                              size: 54,
                              color: const Color(
                                0xFF1B5E20,
                              ).withValues(alpha: 0.08),
                            ),
                          ),
                          // Kartu hadiah di ujung jalur (atas).
                          Positioned(
                            top: 6,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: QuizInfoCard(
                                icon: Icons.monetization_on,
                                iconColor: const Color(0xFFFF8F00),
                                iconBgColor: const Color(0xFFFFF3E0),
                                title: 'Hadiah Spesial',
                                titleHighlight: null,
                                subtitle: '${QuizLevelData.rewardPoints} Poin',
                                maxWidth: 210,
                              ),
                            ),
                          ),
                          // Node 5 (locked) — atas.
                          Positioned(
                            top: 96,
                            left: w * 0.36,
                            child: QuizStageNode(
                              stage: _stage(5),
                              onTap: () => _onNodeTap(context, _stage(5)),
                            ),
                          ),
                          // Kartu motivasi kiri.
                          Positioned(
                            top: 228,
                            left: 12,
                            child: QuizInfoCard(
                              icon: Icons.recycling,
                              iconColor: const Color(0xFF43A047),
                              iconBgColor: const Color(0xFFE8F5E9),
                              subtitle: 'Terus belajar,\nselamatkan bumi!',
                              maxWidth: 150,
                            ),
                          ),
                          // Node 4 (locked) — kanan tengah.
                          Positioned(
                            top: 236,
                            left: w * 0.55,
                            child: QuizStageNode(
                              stage: _stage(4),
                              onTap: () => _onNodeTap(context, _stage(4)),
                            ),
                          ),
                          // Node 3 (aktif) + tooltip.
                          Positioned(
                            top: 372,
                            left: w * 0.30,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const QuizActiveTooltip(),
                                const SizedBox(height: 2),
                                QuizStageNode(
                                  stage: _stage(3),
                                  onTap: () => _onNodeTap(context, _stage(3)),
                                ),
                              ],
                            ),
                          ),
                          // Kartu motivasi kanan.
                          Positioned(
                            top: 420,
                            right: 12,
                            child: QuizInfoCard(
                              icon: Icons.lightbulb_outline,
                              iconColor: const Color(0xFFFFA000),
                              iconBgColor: const Color(0xFFFFF8E1),
                              subtitle:
                                  'Setiap jawaban\nmembawamu ke\nmasa depan yang\nlebih hijau!',
                              maxWidth: 150,
                            ),
                          ),
                          // Node 2 & 1 (completed) — bawah.
                          Positioned(
                            top: 540,
                            left: w * 0.52,
                            child: QuizStageNode(
                              stage: _stage(2),
                              onTap: () => _onNodeTap(context, _stage(2)),
                            ),
                          ),
                          Positioned(
                            top: 600,
                            left: w * 0.28,
                            child: QuizStageNode(
                              stage: _stage(1),
                              onTap: () => _onNodeTap(context, _stage(1)),
                            ),
                          ),
                          // Kartu hadiah kecil dekoratif kiri bawah.
                          Positioned(
                            bottom: 8,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.07),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.card_giftcard,
                                color: Color(0xFF43A047),
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
