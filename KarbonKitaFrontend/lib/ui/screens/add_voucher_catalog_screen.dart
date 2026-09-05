import 'package:flutter/material.dart';

class AddVoucherCatalogScreen extends StatefulWidget {
  const AddVoucherCatalogScreen({super.key});

  @override
  State<AddVoucherCatalogScreen> createState() =>
      _AddVoucherCatalogScreenState();
}

class _AddVoucherCatalogScreenState extends State<AddVoucherCatalogScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedMitra = 'Bakery & Cafe Nusantara - RT 05';
  final _namaController = TextEditingController(
    text: 'Voucher Potongan Rp 20.000',
  );
  final _syaratController = TextEditingController();
  final _diskonController = TextEditingController(text: '20000');
  final _pointsController = TextEditingController(text: '500');
  final _stokController = TextEditingController(text: '100');
  final _expiryController = TextEditingController(text: '31 Desember 2026');
  DateTime _selectedDate = DateTime(2026, 12, 31);
  bool _pickedImage = false;

  final List<String> _mitraOptions = [
    'Bakery & Cafe Nusantara - RT 05',
    'Warung Sehat Ibu Ani - RT 03',
    'Kopi Lokal Surabaya - RT 02',
    'Dapur Sehat Ibu - RT 07',
  ];

  @override
  void dispose() {
    _namaController.dispose();
    _syaratController.dispose();
    _diskonController.dispose();
    _pointsController.dispose();
    _stokController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2028, 12, 31),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF1B8039)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _expiryController.text = _formatDate(picked);
      });
    }
  }

  void _handleSimpan() {
    if (_selectedMitra == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih mitra UMKM terlebih dahulu')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Voucher disimpan (dummy) — akan muncul di Green Marketplace',
        ),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _fieldLabel(Icons.storefront, 'Pilih Mitra UMKM'),
                      const SizedBox(height: 8),
                      _buildMitraDropdown(),
                      const SizedBox(height: 16),
                      _fieldLabel(
                        Icons.local_offer_outlined,
                        'Nama Voucher / Diskon',
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _namaController,
                        hint: 'Voucher Potongan Rp 20.000',
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Nama voucher wajib diisi';
                          }
                          if (v.trim().length < 5) {
                            return 'Minimal 5 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _fieldLabel(
                        Icons.description_outlined,
                        'Syarat & Ketentuan Berlaku',
                      ),
                      const SizedBox(height: 8),
                      _buildTextArea(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel(
                                  Icons.sell_outlined,
                                  'Nilai Diskon (Rp)',
                                ),
                                const SizedBox(height: 8),
                                _buildNumberField(
                                  controller: _diskonController,
                                  hint: '20000',
                                  prefixText: 'Rp ',
                                  icon: Icons.sell_outlined,
                                  validator: (v) {
                                    final n = int.tryParse(v ?? '');
                                    if (n == null || n <= 0) {
                                      return 'Wajib angka >0';
                                    }
                                    if (n > 1000000) {
                                      return 'Max 1jt';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: _fieldLabel(
                                        Icons.eco,
                                        'Harga Penukaran',
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '(Eco)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => _pointsController.clear(),
                                      child: Icon(
                                        Icons.close,
                                        size: 14,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _buildEcoField(),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel(
                                  Icons.card_giftcard,
                                  'Kuota / Stok Voucher',
                                ),
                                const SizedBox(height: 8),
                                _buildNumberField(
                                  controller: _stokController,
                                  hint: '100',
                                  icon: Icons.inventory_2_outlined,
                                  validator: (v) {
                                    final n = int.tryParse(v ?? '');
                                    if (n == null || n < 1) return 'Min 1';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel(
                                  Icons.calendar_today_outlined,
                                  'Masa Berlaku Hingga',
                                ),
                                const SizedBox(height: 8),
                                _buildDateField(),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _fieldLabel(
                        Icons.image_outlined,
                        'Upload Foto Produk/Voucher',
                      ),
                      const SizedBox(height: 8),
                      _buildDashedUpload(),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _handleSimpan,
                          icon: const Icon(Icons.check_circle, size: 18),
                          label: const Text(
                            'Simpan Voucher',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B8039),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Voucher akan langsung muncul di Green Marketplace warga',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, size: 18, color: Colors.black87),
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tambah Katalog Voucher Baru',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Voucher yang ditambahkan akan langsung muncul di Green Marketplace warga',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black54,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.black54),
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }

  Widget _fieldLabel(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF1B8039)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMitraDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedMitra,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: Colors.grey.shade600,
            size: 20,
          ),
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
          hint: Text(
            'Pilih mitra',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
          items: _mitraOptions
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _selectedMitra = v),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        style: const TextStyle(fontSize: 13, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTextArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextFormField(
            controller: _syaratController,
            maxLines: 4,
            minLines: 3,
            maxLength: 500,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              height: 1.4,
            ),
            decoration: InputDecoration(
              hintText:
                  'Berlaku untuk semua menu tanpa minimum belanja. Tidak dapat digabung dengan promo lain.',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(14),
              counterText: '',
            ),
            onChanged: (_) => setState(() {}),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12, bottom: 8),
            child: Text(
              '${_syaratController.text.length} / 500',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String hint,
    String? prefixText,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: TextInputType.number,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.black87,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade400,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(icon, size: 16, color: Colors.grey.shade600),
          prefixText: prefixText,
          prefixStyle: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildEcoField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextFormField(
        controller: _pointsController,
        keyboardType: TextInputType.number,
        validator: (v) {
          final n = int.tryParse(v ?? '');
          if (n == null || n < 50) return 'Min 50';
          if (n > 10000) return 'Max 10k';
          return null;
        },
        style: const TextStyle(
          fontSize: 13,
          color: Colors.black87,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: '500',
          hintStyle: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade400,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(10),
            child: Image.asset(
              'assets/images/ecopoints.png',
              width: 18,
              height: 18,
              errorBuilder: (c, e, s) =>
                  const Icon(Icons.eco, color: Color(0xFF1B8039), size: 18),
            ),
          ),
          suffixIcon: IconButton(
            icon: Icon(Icons.cancel, size: 18, color: Colors.grey.shade400),
            onPressed: () => setState(() => _pointsController.clear()),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: _pickDate,
      child: AbsorbPointer(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextFormField(
            controller: _expiryController,
            readOnly: true,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: '31 Desember 2026',
              prefixIcon: Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: Colors.grey.shade600,
              ),
              suffixIcon: Icon(
                Icons.keyboard_arrow_down,
                size: 18,
                color: Colors.grey.shade600,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'Wajib isi';
              }
              if (_selectedDate.isBefore(DateTime.now())) {
                return 'Harus masa depan';
              }
              return null;
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDashedUpload() {
    return GestureDetector(
      onTap: () => setState(() => _pickedImage = !_pickedImage),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: const Color(0xFF1B8039).withValues(alpha: 0.35),
          radius: 12,
        ),
        child: Container(
          height: 130,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: _pickedImage
              ? Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F8E9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(
                                  0xFF1B8039,
                                ).withValues(alpha: 0.2),
                              ),
                            ),
                            child: const Icon(
                              Icons.image,
                              color: Color(0xFF1B8039),
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'foto_voucher.jpg',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '1.2 MB • Tap untuk ganti',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _pickedImage = false),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cloud_upload_outlined,
                        color: Color(0xFF1B8039),
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Icon(
                      Icons.arrow_upward,
                      color: Color(0xFF43A047),
                      size: 18,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap untuk upload foto',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'PNG, JPG hingga 5MB (opsional)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  _DashedBorderPainter({required this.color, required this.radius});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    const dash = 6.0;
    const gap = 4.0;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final dashed = _dashPath(path, dashWidth: dash, dashSpace: gap);
    canvas.drawPath(dashed, paint);
  }

  Path _dashPath(
    Path source, {
    required double dashWidth,
    required double dashSpace,
  }) {
    final dashed = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = dashWidth;
        dashed.addPath(
          metric.extractPath(distance, distance + next),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    return dashed;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
