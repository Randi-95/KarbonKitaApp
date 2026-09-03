import 'package:flutter/material.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  int _selectedTab = 0; // 0 = Minggu Ini, 1 = Bulan Ini
  int _selectedCategory = 0; // 0 = Individu Warga, 1 = Antar RT/RW

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildTabToggle(),
                    const SizedBox(height: 16),
                    _buildCategoryToggle(),
                    const SizedBox(height: 20),
                    _buildTop3Podium(),
                    const SizedBox(height: 20),
                    _buildRankingList(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            _buildBottomCurrentUser(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.emoji_events, color: Colors.grey, size: 28),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Papan Peringkat',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.grey, size: 22),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildTabToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTab == 0 ? Colors.green : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Minggu Ini',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _selectedTab == 0 ? Colors.white : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTab == 1 ? Colors.green : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Bulan Ini',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _selectedTab == 1 ? Colors.white : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _selectedCategory == 0
                        ? Colors.green
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person,
                      size: 18,
                      color: _selectedCategory == 0
                          ? Colors.green
                          : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Individu Warga',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _selectedCategory == 0
                            ? Colors.green
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _selectedCategory == 1
                        ? Colors.green
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.group,
                      size: 18,
                      color: _selectedCategory == 1
                          ? Colors.green
                          : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Antar RT/RW',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _selectedCategory == 1
                            ? Colors.green
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTop3Podium() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place
          Expanded(
            child: _buildPodiumStep(
              rank: 2,
              name: 'Alya Nabila',
              rt: 'RT 05 / RW 02',
              points: '2.890',
              stepHeight: 70,
              stepColor: Colors.blueGrey,
              badgeColor: Colors.blueGrey,
              avatarBg: Colors.blueGrey.shade100,
              avatarIcon: Colors.blueGrey,
            ),
          ),
          const SizedBox(width: 8),
          // 1st place (center, tallest)
          Expanded(
            flex: 2,
            child: _buildPodiumStep(
              rank: 1,
              name: 'Reza Rahardian',
              rt: 'RT 05 / RW 02',
              points: '3.450',
              stepHeight: 100,
              stepColor: Colors.amber,
              badgeColor: Colors.amber,
              avatarBg: const Color(0xFFFFF8E1),
              avatarIcon: Colors.amber,
              isTop1: true,
            ),
          ),
          const SizedBox(width: 8),
          // 3rd place
          Expanded(
            child: _buildPodiumStep(
              rank: 3,
              name: 'Dika',
              rt: 'RT 05 / RW 02',
              points: '2.350',
              stepHeight: 55,
              stepColor: Colors.orange,
              badgeColor: Colors.orange,
              avatarBg: const Color(0xFFFFF3E0),
              avatarIcon: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumStep({
    required int rank,
    required String name,
    required String rt,
    required String points,
    required double stepHeight,
    required Color stepColor,
    required Color badgeColor,
    required Color avatarBg,
    required Color avatarIcon,
    bool isTop1 = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Rank badge
        if (isTop1)
          const Icon(Icons.workspace_premium, color: Colors.amber, size: 30)
        else
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$rank',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        const SizedBox(height: 4),
        // Avatar
        CircleAvatar(
          radius: isTop1 ? 26 : 20,
          backgroundColor: avatarBg,
          child: Icon(
            Icons.person,
            size: isTop1 ? 28 : 22,
            color: avatarIcon,
          ),
        ),
        const SizedBox(height: 4),
        // Name
        Text(
          name,
          style: TextStyle(
            fontSize: isTop1 ? 13 : 11,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        // RT
        Text(
          rt,
          style: TextStyle(fontSize: isTop1 ? 10 : 9, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        // Points
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/ecopoints.png',
              width: isTop1 ? 16 : 14,
              height: isTop1 ? 16 : 14,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.eco, color: Colors.green, size: isTop1 ? 16 : 14),
            ),
            const SizedBox(width: 3),
            Text(
              points,
              style: TextStyle(
                fontSize: isTop1 ? 16 : 13,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1B8039),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Podium step
        Container(
          width: double.infinity,
          height: stepHeight,
          decoration: BoxDecoration(
            color: stepColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
            boxShadow: [
              BoxShadow(
                color: stepColor.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: isTop1 ? 36 : 28,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRankingList() {
    final rankings = [
      {'rank': 4, 'name': 'Devon Lane', 'rt': 'RT 05 / RW 02', 'points': '738'},
      {'rank': 5, 'name': 'Guy Hawkins', 'rt': 'RT 05 / RW 02', 'points': '703'},
      {'rank': 6, 'name': 'Marvin McKinney', 'rt': 'RT 05 / RW 02', 'points': '447'},
      {'rank': 7, 'name': 'Theresa Webb', 'rt': 'RT 05 / RW 02', 'points': '429'},
      {'rank': 8, 'name': 'Ronald Richards', 'rt': 'RT 05 / RW 02', 'points': '357'},
      {'rank': 9, 'name': 'Savannah Nguyen', 'rt': 'RT 05 / RW 02', 'points': '154'},
      {'rank': 10, 'name': 'Jane Cooper', 'rt': 'RT 05 / RW 02', 'points': '130'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: List.generate(rankings.length, (index) {
          final item = rankings[index];
          return _buildRankingItem(
            rank: item['rank'] as int,
            name: item['name'] as String,
            rt: item['rt'] as String,
            points: item['points'] as String,
            isLast: index == rankings.length - 1,
          );
        }),
      ),
    );
  }

  Widget _buildRankingItem({
    required int rank,
    required String name,
    required String rt,
    required String points,
    required bool isLast,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: Colors.grey.shade100, width: 1),
              ),
      ),
      child: Row(
        children: [
          // Rank number
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFE8F5E9),
            child: const Icon(Icons.person, color: Color(0xFF1B8039), size: 20),
          ),
          const SizedBox(width: 12),
          // Name & RT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  rt,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Points
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/ecopoints.png',
                width: 18,
                height: 18,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.eco, color: Colors.green, size: 18),
              ),
              const SizedBox(width: 4),
              Text(
                points,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B8039),
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'Poin',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        ],
      ),
    );
  }

  Widget _buildBottomCurrentUser() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.green, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Trophy + rank
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events, color: Colors.green, size: 22),
              const SizedBox(width: 4),
              const Text(
                '3',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFE8F5E9),
            child: const Icon(Icons.person, color: Color(0xFF1B8039), size: 20),
          ),
          const SizedBox(width: 12),
          // Name & RT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Dika (kamu)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'RT 05 / RW 02',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Points
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/ecopoints.png',
                width: 18,
                height: 18,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.eco, color: Colors.green, size: 18),
              ),
              const SizedBox(width: 4),
              const Text(
                '2.350',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B8039),
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'Poin',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: Colors.green, size: 20),
        ],
      ),
    );
  }
}
