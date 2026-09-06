import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class DompetVoucherScreen extends StatefulWidget {
  const DompetVoucherScreen({super.key});

  @override
  State<DompetVoucherScreen> createState() => _DompetVoucherScreenState();
}

class _DompetVoucherScreenState extends State<DompetVoucherScreen> {
  int _selectedTab = 0;

  final List<String> _tabLabels = ['Voucher Aktif', 'Riwayat', 'Kedaluwarsa'];
  final List<int> _tabCounts = [3, 4, 2];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F6),
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(child: _buildVoucherList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: Color(0xFFEAF5EB)),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -10,
              child: CustomPaint(
                size: const Size(140, 140),
                painter: _BlobPainter(),
              ),
            ),
            Positioned(
              right: 40,
              top: 50,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFFC8D84A),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_back_ios,
                          color: Color(0xFF2D3436),
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Kembali ke Marketplace',
                          style: TextStyle(
                            color: Color(0xFF2D3436),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 28),
                    child: Text(
                      'Dompet Voucher Saya',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: const Color(0xFFF5F9F6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(_tabLabels.length, (index) {
            final isSelected = _selectedTab == index;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTab = index;
                });
              },
              child: Container(
                margin: EdgeInsets.only(
                  right: index < _tabLabels.length - 1 ? 12 : 0,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF1E6C46)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _tabLabels[index],
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF6B7B74),
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                    if (_tabCounts[index] > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.25)
                              : const Color(0xFFE0E5E2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_tabCounts[index]}',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF6B7B74),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildVoucherList() {
    final vouchers = _getVouchersForTab();

    if (vouchers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Tidak ada voucher',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: vouchers.length,
      itemBuilder: (context, index) {
        return _buildVoucherCard(vouchers[index]);
      },
    );
  }

  List<Map<String, dynamic>> _getVouchersForTab() {
    switch (_selectedTab) {
      case 0:
        return [
          {
            'storeName': 'Kedai Kopi Nusantara',
            'discount': 'Rp 15.000',
            'expiry': '28 Jun 2025',
            'leftColor': const Color(0xFF234A2F),
            'logoIcon': Icons.coffee,
            'iconColor': const Color(0xFFB5651D),
            'logoLine1': 'KEDAI KOPI',
            'logoLine2': 'NUSANTARA',
          },
          {
            'storeName': 'OrganikKu Store',
            'discount': 'Rp 10.000',
            'expiry': '20 Jun 2025',
            'leftColor': const Color(0xFF3E2063),
            'logoIcon': Icons.eco,
            'iconColor': const Color(0xFF2E9E4B),
            'logoLine1': 'OrganikKu',
            'logoLine2': '',
          },
        ];
      case 1:
        return [
          {
            'storeName': 'Toko Hijau',
            'discount': 'Rp 5.000',
            'expiry': '15 Mar 2025',
            'leftColor': const Color(0xFF234A2F),
            'logoIcon': Icons.storefront,
            'iconColor': const Color(0xFF2E9E4B),
            'logoLine1': 'TOKO',
            'logoLine2': 'HIJAU',
          },
        ];
      case 2:
        return [
          {
            'storeName': 'Rumah Organik',
            'discount': 'Rp 8.000',
            'expiry': '1 Jan 2025',
            'leftColor': const Color(0xFF7A8A7E),
            'logoIcon': Icons.spa,
            'iconColor': Colors.grey,
            'logoLine1': 'RUMAH',
            'logoLine2': 'ORGANIK',
          },
        ];
      default:
        return [];
    }
  }

  Widget _buildVoucherCard(Map<String, dynamic> voucher) {
    final bool isExpired = _selectedTab == 2;
    const double leftWidth = 122;
    const double toothDepth = 5;
    const double radius = 12;
    const Color pageBg = Color(0xFFF5F9F6);
    final Color leftColor = isExpired
        ? const Color(0xFF7A8A7E)
        : (voucher['leftColor'] as Color? ?? const Color(0xFF234A2F));

    return GestureDetector(
      onTap: () => _onVoucherTap(voucher, isExpired),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Stack(
            children: [
              // dasar abu muda (mengikuti tinggi isi)
              Positioned.fill(child: Container(color: const Color(0xFFF1F3F1))),
              // kiri: hijau tua + gerigi, ikut setinggi card
              Positioned.fill(
                right: null,
                child: ClipPath(
                  clipper: _SerratedLeftClipper(
                    leftWidth: leftWidth,
                    radius: radius,
                    toothHeight: 9,
                    toothDepth: toothDepth,
                  ),
                  child: Container(
                    width: leftWidth + toothDepth,
                    color: leftColor,
                    child: Stack(
                      children: [
                        // aksen daun samar
                        Positioned(
                          left: 16,
                          bottom: 10,
                          child: Transform.rotate(
                            angle: -0.5,
                            child: Container(
                              width: 48,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.07),
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(20),
                                  bottomLeft: Radius.circular(20),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(right: toothDepth),
                            child: _buildLogoCircle(voucher, isExpired),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // coakan tiket atas & bawah
              Positioned(
                left: leftWidth - 8,
                top: -8,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: pageBg,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left: leftWidth - 8,
                bottom: -8,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: pageBg,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // konten kanan (penentu tinggi card)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(width: leftWidth + toothDepth + 6),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(6, 12, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: isExpired
                                    ? Colors.grey.shade400
                                    : const Color(0xFF34A853),
                                width: 1.2,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'VOUCHER DISKON',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                                color: isExpired
                                    ? Colors.grey.shade500
                                    : const Color(0xFF2E9E4B),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          RichText(
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.25,
                                color: Color(0xFF111111),
                              ),
                              children: [
                                const TextSpan(
                                  text: 'Potongan ',
                                  style: TextStyle(fontWeight: FontWeight.w400),
                                ),
                                TextSpan(
                                  text: '${voucher['discount']} -',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                TextSpan(
                                  text: '\n${voucher['storeName']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 12,
                                color: Color(0xFF9AA3A0),
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  isExpired
                                      ? 'Kedaluwarsa ${voucher['expiry']}'
                                      : 'Berlaku hingga ${voucher['expiry']}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    height: 1.2,
                                    color: Color(0xFF8A938F),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onVoucherTap(Map<String, dynamic> voucher, bool isExpired) {
    if (isExpired || _selectedTab == 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voucher sudah kedaluwarsa')),
      );
      return;
    }
    final token = _dummyToken(voucher['storeName'] as String? ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RedeemSheet(
        storeName: voucher['storeName'] as String? ?? '',
        token: token,
      ),
    );
  }

  String _dummyToken(String seed) {
    final h = seed.hashCode.abs();
    final a = (1000 + h % 9000).toString();
    final b = (1000 + (h ~/ 7) % 9000).toString();
    return '$a-$b';
  }

  Widget _buildLogoCircle(Map<String, dynamic> voucher, bool isExpired) {
    return Container(
      width: 74,
      height: 74,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              voucher['logoIcon'] as IconData? ?? Icons.coffee,
              size: 24,
              color: isExpired
                  ? Colors.grey.shade500
                  : (voucher['iconColor'] as Color? ?? const Color(0xFFB5651D)),
            ),
            const SizedBox(height: 3),
            Text(
              voucher['logoLine1'] ?? '',
              style: const TextStyle(
                fontSize: 7.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A),
                height: 1.1,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              voucher['logoLine2'] ?? '',
              style: const TextStyle(
                fontSize: 7.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A),
                height: 1.1,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2E8B57)
      ..style = PaintingStyle.fill;

    final path1 = Path()
      ..moveTo(size.width * 0.3, 0)
      ..quadraticBezierTo(size.width, 0, size.width, size.height * 0.4)
      ..quadraticBezierTo(
        size.width,
        size.height,
        size.width * 0.5,
        size.height,
      )
      ..quadraticBezierTo(0, size.height, 0, size.height * 0.5)
      ..quadraticBezierTo(0, 0, size.width * 0.3, 0)
      ..close();

    canvas.drawPath(path1, paint);

    final paint2 = Paint()
      ..color = const Color(0xFF3DAA6D)
      ..style = PaintingStyle.fill;

    final path2 = Path()
      ..moveTo(size.width * 0.5, size.height * 0.1)
      ..quadraticBezierTo(
        size.width,
        size.height * 0.1,
        size.width,
        size.height * 0.5,
      )
      ..quadraticBezierTo(
        size.width,
        size.height * 0.9,
        size.width * 0.6,
        size.height * 0.85,
      )
      ..quadraticBezierTo(
        size.width * 0.2,
        size.height * 0.8,
        size.width * 0.3,
        size.height * 0.5,
      )
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.15,
        size.width * 0.5,
        size.height * 0.1,
      )
      ..close();

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SerratedLeftClipper extends CustomClipper<Path> {
  final double leftWidth;
  final double radius;
  final double toothHeight;
  final double toothDepth;

  _SerratedLeftClipper({
    required this.leftWidth,
    required this.radius,
    this.toothHeight = 9,
    this.toothDepth = 5,
  });

  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(0, radius)
      ..quadraticBezierTo(0, 0, radius, 0)
      ..lineTo(leftWidth, 0);

    double y = 0;
    bool out = true;
    while (y < size.height) {
      y += toothHeight;
      if (y > size.height) y = size.height;
      path.lineTo(out ? leftWidth + toothDepth : leftWidth, y);
      out = !out;
    }

    path
      ..lineTo(radius, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - radius)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _RedeemSheet extends StatefulWidget {
  final String storeName;
  final String token;

  const _RedeemSheet({required this.storeName, required this.token});

  @override
  State<_RedeemSheet> createState() => _RedeemSheetState();
}

class _RedeemSheetState extends State<_RedeemSheet> {
  static const int _totalSeconds = 5 * 60;
  int _remaining = _totalSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 1) {
        t.cancel();
        if (mounted) setState(() => _remaining = 0);
        return;
      }
      if (mounted) setState(() => _remaining--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _clockText {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield,
                  color: Color(0xFF2E9E4B),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tunjukkan QR ini ke merchant',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Scan untuk menukarkan voucher',
                      style: TextStyle(fontSize: 12, color: Color(0xFF8A938F)),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0F2F0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: 200,
            height: 200,
            child: CustomPaint(
              painter: _DummyQrPainter(seed: widget.storeName.hashCode),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE2E6E2)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.confirmation_number_outlined,
                  size: 16,
                  color: Colors.black54,
                ),
                const SizedBox(width: 8),
                Text(
                  'TOKEN: ${widget.token}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE9F6EC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 18,
                  color: Color(0xFF2E9E4B),
                ),
                const SizedBox(width: 8),
                const Text(
                  'QR berlaku selama',
                  style: TextStyle(fontSize: 13, color: Color(0xFF2E7D32)),
                ),
                const Spacer(),
                Text(
                  _clockText,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E6C46),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE9F6EC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle, size: 18, color: Color(0xFF2E9E4B)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Untuk keamanan, jangan bagikan kode ini kepada siapapun.',
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF2E7D32)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DummyQrPainter extends CustomPainter {
  final int seed;

  _DummyQrPainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = Colors.white;
    canvas.drawRect(Offset.zero & size, bg);

    final fg = Paint()..color = Colors.black;
    const int n = 29;
    final double cell = size.width / n;
    final rand = Random(seed);

    bool inFinder(int x, int y) {
      final inTL = x < 8 && y < 8;
      final inTR = x >= n - 8 && y < 8;
      final inBL = x < 8 && y >= n - 8;
      return inTL || inTR || inBL;
    }

    for (int y = 0; y < n; y++) {
      for (int x = 0; x < n; x++) {
        if (inFinder(x, y)) continue;
        if (rand.nextDouble() < 0.42) {
          canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell, cell), fg);
        }
      }
    }

    void finder(double ox, double oy) {
      const double s = 7;
      canvas.drawRect(Rect.fromLTWH(ox, oy, s * cell, s * cell), fg);
      canvas.drawRect(
        Rect.fromLTWH(ox + cell, oy + cell, 5 * cell, 5 * cell),
        Paint()..color = Colors.white,
      );
      canvas.drawRect(
        Rect.fromLTWH(ox + 2 * cell, oy + 2 * cell, 3 * cell, 3 * cell),
        fg,
      );
    }

    finder(0, 0);
    finder((n - 7) * cell, 0);
    finder(0, (n - 7) * cell);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
