import 'package:flutter/material.dart';

/// Isi bottom sheet hasil validasi AI (mock frontend-only).
/// Disize dari konten ([mainAxisSize.min]) agar ~setengah layar.
class ValidationResultSheet extends StatelessWidget {
  const ValidationResultSheet({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewPadding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 14),
          _buildInfoCards(),
          const SizedBox(height: 12),
          _buildAntiFraudBanner(),
          const SizedBox(height: 14),
          _buildCtaButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/robot.png',
          width: 72,
          height: 72,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.smart_toy_outlined,
              color: Color(0xFF2E9E4B),
              size: 36,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Validasi AI Gemini',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111),
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Sukses!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2E9E4B),
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Sampahmu sudah terverifikasi AI',
                style: TextStyle(fontSize: 12, color: Color(0xFF8A938F)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCards() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _infoCard(
          label: 'Kategori',
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.recycling, color: Color(0xFF2E9E4B), size: 20),
              SizedBox(width: 6),
              Text(
                'Plastik Terpilah',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2E9E4B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _infoCard(
          label: 'Eco Points Didapatkan',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/ecopoints.png',
                width: 22,
                height: 22,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.monetization_on,
                  color: Color(0xFFF9A825),
                  size: 22,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                '+50',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F6EC),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Mantap! 🌿',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoCard({required String label, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E6E2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF8A938F)),
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }

  Widget _buildAntiFraudBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sistem Anti-Fraud Aktif',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E6C46),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Foto dianalisis AI untuk memastikan keaslian dan mendukung lingkungan yang lebih bersih.',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF2E7D32)),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          Icon(Icons.check_circle, size: 18, color: Color(0xFF2E9E4B)),
        ],
      ),
    );
  }

  Widget _buildCtaButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onContinue,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1B8039),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Lanjutkan Misi',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            SizedBox(width: 10),
            Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    );
  }
}
