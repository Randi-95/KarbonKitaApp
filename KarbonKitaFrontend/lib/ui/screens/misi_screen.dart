import 'package:flutter/material.dart';

import 'misi_scan_screen.dart';
import 'mobility_tracker_screen.dart';

class MisiScreen extends StatefulWidget {
  const MisiScreen({super.key});

  @override
  State<MisiScreen> createState() => _MisiScreenState();
}

class _MisiScreenState extends State<MisiScreen> {
  int _selectedCategoryIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildCategoryTabs(),
              const SizedBox(height: 20),
              _buildMissionList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Misi Hijau Harian',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E6C46),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Selesaikan misi, kumpulkan\npoin, dan jaga bumi kita!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time, color: Colors.green, size: 24),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Riset dalam',
                        style: TextStyle(fontSize: 10, color: Colors.green),
                      ),
                      Text(
                        '10:45:12',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.ac_unit, color: Colors.blue, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Streak Freeze: ',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                  Text(
                    'Aktif',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTabItem(0, Icons.grid_view_rounded, 'Semua'),
          _buildTabItem(1, Icons.pedal_bike, 'Mobilitas'),
          _buildTabItem(2, Icons.recycling, 'Sampah'),
          _buildTabItem(3, Icons.help_outline, 'Kuis'),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, IconData icon, String label) {
    bool isSelected = _selectedCategoryIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategoryIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? Colors.green : Colors.grey, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? Colors.green : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 3,
            width: 40,
            decoration: BoxDecoration(
              color: isSelected ? Colors.green : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionList() {
    return Column(
      children: [
        _buildMissionCard(
          icon: Icons.pedal_bike,
          iconBgColor: const Color(0xFFE8F5E9),
          iconColor: Colors.green,
          categoryIcon: Icons.pedal_bike,
          categoryLabel: 'Mobilitas',
          categoryColor: Colors.green,
          title: 'Pejuang Pedal 2Km',
          description: 'catat aktivitasmu dan dapatkan point!',
          points: '+150',
          buttonText: 'Mulai Tracker',
          buttonColor: Colors.green,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MobilityTrackerScreen(
                  missionTitle: 'Pejuang Pedal 2Km',
                  activityType: 'cycling',
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 15),
        _buildMissionCard(
          icon: Icons.delete_outline,
          iconBgColor: const Color(0xFFE8F5E9),
          iconColor: Colors.green,
          categoryIcon: Icons.recycling,
          categoryLabel: 'Sampah',
          categoryColor: Colors.green,
          title: 'Pahlawan Plastik Terpilah',
          description: 'Ambil foto hasil pilah sampahmu!',
          points: '+300',
          buttonText: 'Upload Foto',
          buttonColor: Colors.green,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MisiScanScreen(
                  missionTitle: 'Pahlawan Plastik Terpilah',
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 15),
        _buildMissionCard(
          icon: Icons.help_outline,
          iconBgColor: const Color(0xFFFFF3E0),
          iconColor: Colors.orange,
          categoryIcon: Icons.pedal_bike,
          categoryLabel: 'Mobilitas',
          categoryColor: Colors.orange,
          title: 'Petualangan Kuis Hijau',
          description: 'Kerjakan kuis harian untuk tetap mempertahankan Streak',
          points: '+30',
          buttonText: 'Mulai Quiz',
          buttonColor: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildMissionCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required IconData categoryIcon,
    required String categoryLabel,
    required Color categoryColor,
    required String title,
    required String description,
    required String points,
    required String buttonText,
    required Color buttonColor,
    VoidCallback? onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 30),
              ),
              const SizedBox(width: 12),
              // Middle Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(categoryIcon, color: categoryColor, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            categoryLabel,
                            style: TextStyle(
                              fontSize: 10,
                              color: categoryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Points & Button Row (below the main content)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/ecopoints.png',
                      width: 20,
                      height: 20,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.eco, color: Colors.green, size: 20),
                    ),
                    const SizedBox(width: 4),
                    Column(
                      children: [
                        Text(
                          points,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text('Poin', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: onPressed ?? () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
