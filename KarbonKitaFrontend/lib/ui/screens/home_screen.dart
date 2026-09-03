import 'package:flutter/material.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'misi_screen.dart';
import 'marketplace_screen.dart';
import 'leaderboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onItemTapped(1),
        backgroundColor: const Color(0xFF43A047),
        elevation: 4,
        child: const Icon(Icons.assignment, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildBerandaContent();
      case 1:
        return const MisiScreen();
      case 2:
        return const MarketplaceScreen();
      case 3:
        return const LeaderboardScreen();
      case 4:
        return const Center(
          child: Text(
            'Halaman Profil (Segera Hadir)',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        );
      default:
        return _buildBerandaContent();
    }
  }

  Widget _buildBerandaContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
            child: Image.asset(
              'assets/images/backgroundberanda.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: 310,
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 10),
                _buildProfileSection(),
                const SizedBox(height: 20),
                _buildMisiHarian(),
                const SizedBox(height: 20),
                _buildAksiCepat(),
                const SizedBox(height: 20),
                _buildPapanPeringkat(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Row(
        children: [
          Image.asset(
            'assets/images/logoapp.png',
            height: 40,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.eco, color: Colors.green, size: 30),
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.notifications_none,
                color: Colors.black87,
              ),
              onPressed: () {},
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.card_giftcard, color: Colors.green, size: 20),
                SizedBox(width: 5),
                Text(
                  'Event',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Halo Dika!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Terus jaga bumi, jadi pahlawan hijau!',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 110,
            child: Stack(
              children: [
                // Avatar (left)
                Positioned(
                  left: 0,
                  top: 0,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const CircleAvatar(
                      backgroundColor: Color(0xFFF3E5F5),
                      backgroundImage: AssetImage(
                        'assets/images/avatar.png',
                      ),
                      child: Icon(Icons.person, size: 50, color: Colors.grey),
                    ),
                  ),
                ),
                Positioned(
                  left: 85,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
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
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              'Eco Points',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              '1.250',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Streak & Peringkat (middle bottom)
                Positioned(
                  left: 85,
                  top: 58,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.local_fire_department,
                                  color: Colors.orange,
                                  size: 12,
                                ),
                                SizedBox(width: 3),
                                Text(
                                  'Streak',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              '7 Hari',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.emoji_events,
                                  color: Colors.amber,
                                  size: 12,
                                ),
                                SizedBox(width: 3),
                                Text(
                                  'Peringkat',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Top 8%',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Level badge (right)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.shield,
                            color: Colors.green[600],
                            size: 65,
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'Level',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '12',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 65,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  width: 38,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              '2.350 / 3.500 XP',
                              style: TextStyle(
                                fontSize: 7,
                                color: Colors.black54,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMisiHarian() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
            children: [
              const Icon(
                Icons.local_fire_department,
                color: Colors.deepOrange,
                size: 28,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Misi Harian',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Pilih misi yang ingin kamu kerjakan hari ini!',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lihat Semua',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.green, size: 16),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildMisiCard(
                  icon: Icons.pedal_bike,
                  title: 'Pejuang Pedal 2 km',
                  subtitle: 'Mobilitas 2 Km',
                  points: '+150 Poin',
                  xp: '+250 XP',
                  buttonText: 'Mulai Tracker',
                  buttonColor: Colors.green,
                ),
                const SizedBox(width: 15),
                _buildMisiCard(
                  icon: Icons.delete_outline,
                  title: 'Pahlawan Plastik\nTerpilah',
                  subtitle: 'Pilah & Upload',
                  points: '+300 Poin',
                  xp: '+450 XP',
                  buttonText: 'Selesaikan Misi',
                  buttonColor: Colors.orangeAccent,
                ),
                const SizedBox(width: 15),
                _buildMisiCard(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Diet Kantong\nPlastik',
                  subtitle: 'Literasi Lingkungan',
                  points: '+100 Poin',
                  xp: '+150 XP',
                  buttonText: 'Selesaikan Misi',
                  buttonColor: Colors.green,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMisiCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String points,
    required String xp,
    required String buttonText,
    required Color buttonColor,
  }) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.green),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: Colors.black54),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.eco, color: Colors.green, size: 12),
                const SizedBox(width: 2),
                Text(
                  points,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(Icons.flash_on, color: Colors.lime, size: 12),
                Text(
                  xp,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAksiCepat() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aksi Cepat',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildAksiButton(Icons.calculate, 'Kalkulator Emisi')),
              const SizedBox(width: 10),
              Expanded(child: _buildAksiButton(Icons.quiz, 'Kuis Harian')),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/backgroundstreak.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.green.withOpacity(0.1),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              'Streak Hebat!',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Pertahankan streakmu\ndan dapatkan bonus!',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAksiButton(IconData icon, String label) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.green, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPapanPeringkat() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Papan Peringkat RT 05',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lihat Semua',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.green, size: 16),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPeringkatCard(
                  '2',
                  'Alya Nabila',
                  '2.890 XP',
                  Colors.blueGrey,
                  false,
                ),
                const SizedBox(width: 10),
                _buildPeringkatCard(
                  '1',
                  'Reza Rahardian',
                  '3.450 XP',
                  Colors.amber,
                  true,
                ),
                const SizedBox(width: 10),
                _buildPeringkatCard(
                  '3',
                  'Dika',
                  '2.350 XP',
                  Colors.orange,
                  false,
                  isCurrentUser: true,
                ),
                const SizedBox(width: 10),
                _buildCurrentPeringkatCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeringkatCard(
    String rank,
    String name,
    String xp,
    Color badgeColor,
    bool isTop1, {
    bool isCurrentUser = false,
  }) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isTop1
            ? badgeColor.withOpacity(0.2)
            : (isCurrentUser
                  ? Colors.orange.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isTop1
              ? badgeColor
              : (isCurrentUser ? Colors.orange : Colors.transparent),
        ),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.topLeft,
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: isTop1
                    ? badgeColor.withOpacity(0.5)
                    : Colors.grey[300],
                child: Icon(
                  Icons.person,
                  color: isTop1 ? Colors.white : Colors.grey[600],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  rank,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(xp, style: const TextStyle(fontSize: 10, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildCurrentPeringkatCard() {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.green.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text(
            'Peringkatmu',
            style: TextStyle(fontSize: 10, color: Colors.black54),
          ),
          SizedBox(height: 5),
          Text(
            '#3',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          SizedBox(height: 5),
          Text('2.350 XP', style: TextStyle(fontSize: 10, color: Colors.green)),
        ],
      ),
    );
  }

  int _navIndexToSelected(int navIndex) {
    if (navIndex == 0) return 0;
    return navIndex + 1;
  }

  int _selectedToNavIndex() {
    if (_selectedIndex == 0) return 0;
    if (_selectedIndex == 1) return -1;
    if (_selectedIndex >= 2) return _selectedIndex - 1;
    return 0;
  }

  Widget _buildBottomNavigationBar() {
    final iconList = <IconData>[
      Icons.home,
      Icons.storefront,
      Icons.emoji_events,
      Icons.person_outline,
    ];

    return AnimatedBottomNavigationBar(
      icons: iconList,
      activeIndex: _selectedToNavIndex(),
      onTap: (navIndex) => _onItemTapped(_navIndexToSelected(navIndex)),
      gapLocation: GapLocation.center,
      notchSmoothness: NotchSmoothness.smoothEdge,
      leftCornerRadius: 16,
      rightCornerRadius: 16,
      backgroundColor: Colors.white,
      activeColor: const Color(0xFF43A047),
      inactiveColor: Colors.grey,
      elevation: 8,
    );
  }
}
