import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../core/storage/pick_copy.dart';
import '../widgets/validation_error_sheet.dart';

/// Form pendaftaran Mitra UMKM: `POST /api/auth/register-mitra`.
///
/// Multipart: field teks + foto KTP/NIB/toko (wajib) + 2 foto toko opsional.
/// Sukses → auto-login, SessionGate mengarahkan ke dashboard merchant
/// (status pending, redeem terkunci sampai admin approve).
class MitraRegisterScreen extends StatefulWidget {
  const MitraRegisterScreen({super.key});

  @override
  State<MitraRegisterScreen> createState() => _MitraRegisterScreenState();
}

class _MitraRegisterScreenState extends State<MitraRegisterScreen> {
  static const _green = Color(0xFF1B8039);

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();
  final _city = TextEditingController();
  final _district = TextEditingController();
  final _subDistrict = TextEditingController();
  final _rt = TextEditingController();
  final _rw = TextEditingController();

  final _namaUsaha = TextEditingController();
  final _jenisUsaha = TextEditingController();
  final _alamatUsaha = TextEditingController();
  final _usahaKelurahan = TextEditingController();
  final _usahaKecamatan = TextEditingController();
  final _usahaKota = TextEditingController();
  final _usahaProvinsi = TextEditingController();
  final _usahaKodePos = TextEditingController();

  final _nomorKtp = TextEditingController();
  final _nomorNib = TextEditingController();

  final _namaBank = TextEditingController();
  final _nomorRekening = TextEditingController();
  final _namaPemilikRekening = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final ImagePicker _picker = ImagePicker();
  XFile? _fotoKtp;
  XFile? _fotoNib;
  XFile? _fotoToko;
  XFile? _fotoToko2;
  XFile? _fotoToko3;

  @override
  void initState() {
    super.initState();
    // Bersihkan sisa salinan sesi sebelumnya (best-effort).
    unawaited(clearStalePersistedPhotos());
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _email,
      _phone,
      _password,
      _passwordConfirm,
      _city,
      _district,
      _subDistrict,
      _rt,
      _rw,
      _namaUsaha,
      _jenisUsaha,
      _alamatUsaha,
      _usahaKelurahan,
      _usahaKecamatan,
      _usahaKota,
      _usahaProvinsi,
      _usahaKodePos,
      _nomorKtp,
      _nomorNib,
      _namaBank,
      _nomorRekening,
      _namaPemilikRekening,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto(String field) async {
    // image_picker tidak mendukung kamera di Flutter Web — langsung galeri.
    final ImageSource? source;
    if (kIsWeb) {
      source = ImageSource.gallery;
    } else {
      source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: _green),
                title: const Text('Ambil dari Kamera'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: _green),
                title: const Text('Pilih dari Galeri'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
    }
    if (source == null || !mounted) return;
    XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
    } catch (_) {
      picked = null;
    }
    if (picked == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            kIsWeb
                ? 'Gagal membuka galeri. Coba lagi.'
                : 'Gagal mengambil foto. Coba lagi.',
          ),
        ),
      );
      return;
    }
    // Amankan ke direktori dokumen (anti penggusuran cache OS). Di web
    // passthrough. Hapus foto lama field ini agar tidak menumpuk.
    XFile? stable = picked;
    try {
      stable = await persistPickedPhoto(picked, field) ?? picked;
    } catch (_) {
      stable = picked;
    }
    final previous = _photoOf(field);
    if (!mounted) return;
    setState(() {
      _setPhoto(field, stable);
    });
    if (previous != null && previous.path != stable.path) {
      unawaited(discardPersistedPhoto(previous));
    }
  }

  XFile? _photoOf(String field) {
    switch (field) {
      case 'foto_ktp':
        return _fotoKtp;
      case 'foto_nib':
        return _fotoNib;
      case 'foto_toko':
        return _fotoToko;
      case 'foto_toko_2':
        return _fotoToko2;
      case 'foto_toko_3':
        return _fotoToko3;
    }
    return null;
  }

  void _setPhoto(String field, XFile? file) {
    switch (field) {
      case 'foto_ktp':
        _fotoKtp = file;
      case 'foto_nib':
        _fotoNib = file;
      case 'foto_toko':
        _fotoToko = file;
      case 'foto_toko_2':
        _fotoToko2 = file;
      case 'foto_toko_3':
        _fotoToko3 = file;
    }
  }

  String? _required(String value, String label) {
    if (value.trim().isEmpty) return '$label wajib diisi.';
    return null;
  }

  /// Isi seluruh field teks dengan data valid + unik (dev only).
  /// Foto tetap dipilih manual karena harus file gambar asli.
  void _seedForm() {
    final stamp = DateTime.now().millisecondsSinceEpoch.toString();
    final short = stamp.substring(stamp.length - 6);
    final digits12 = '${stamp}000000000000'.substring(0, 12);
    final name = 'Toko Seed $short';
    setState(() {
      _name.text = name;
      _email.text = 'seed$stamp@toko.id';
      _phone.text = '+628${stamp.substring(stamp.length - 10)}';
      _password.text = 'Password123';
      _passwordConfirm.text = 'Password123';
      _city.text = 'Surabaya';
      _district.text = 'Gubeng';
      _subDistrict.text = 'Mojo';
      _rt.text = '005';
      _rw.text = '02';
      _namaUsaha.text = 'Warung Seed $short';
      _jenisUsaha.text = 'Kelontong';
      _alamatUsaha.text = 'Jl. Seed No. $short, Surabaya';
      _usahaKelurahan.text = 'Mojo';
      _usahaKecamatan.text = 'Gubeng';
      _usahaKota.text = 'Surabaya';
      _usahaProvinsi.text = 'Jawa Timur';
      _usahaKodePos.text = '60111';
      _nomorKtp.text = '3578$digits12';
      _nomorNib.text = 'NIB$stamp';
      _namaBank.text = 'Bank BCA';
      _nomorRekening.text = '1234567890';
      _namaPemilikRekening.text = name;
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Form terisi otomatis. Tinggal pilih 3 foto.'),
        ),
      );
  }

  /// Batas backend MITRA_MAX_FILE_KB (default 5120). Dicek di client agar
  /// user langsung tahu file mana yang kebesaran tanpa round-trip server.
  static const int _maxPhotoBytes = 5120 * 1024;

  static const Map<String, String> _photoLabels = {
    'foto_ktp': 'Foto KTP',
    'foto_nib': 'Foto NIB',
    'foto_toko': 'Foto depan toko',
    'foto_toko_2': 'Foto toko 2',
    'foto_toko_3': 'Foto toko 3',
  };

  /// Baca ukuran file dengan retry: file kamera/galeri kadang belum siap
  /// dibaca sepersekian detik setelah dipilih (media store indexing).
  /// Return null bila tetap tak terbaca setelah 3x coba.
  Future<int?> _readFileSize(XFile file) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        return await file.length();
      } catch (_) {
        if (attempt < 2) {
          await Future.delayed(const Duration(milliseconds: 400));
        }
      }
    }
    return null;
  }

  void _submit() async {
    // Validasi ringan client-side; validasi penuh tetap di backend.
    final checks = <String?>[
      _required(_name.text, 'Nama'),
      _required(_email.text, 'Email'),
      _required(_phone.text, 'No HP'),
      _required(_password.text, 'Kata sandi'),
      _required(_namaUsaha.text, 'Nama usaha'),
      _required(_jenisUsaha.text, 'Jenis usaha'),
      _required(_alamatUsaha.text, 'Alamat usaha'),
      _required(_city.text, 'Kota domisili'),
      _required(_nomorKtp.text, 'Nomor KTP'),
      _required(_nomorNib.text, 'Nomor NIB'),
      _required(_namaBank.text, 'Nama bank'),
      _required(_nomorRekening.text, 'Nomor rekening'),
      _required(_namaPemilikRekening.text, 'Nama pemilik rekening'),
    ];
    final firstError = checks.whereType<String>().firstOrNull;
    if (firstError != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(firstError)));
      return;
    }
    if (!_email.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Format email tidak valid.')),
      );
      return;
    }
    if (_password.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kata sandi minimal 8 karakter.')),
      );
      return;
    }
    if (_password.text != _passwordConfirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konfirmasi kata sandi tidak cocok.')),
      );
      return;
    }
    if (!RegExp(r'^[0-9]{16}$').hasMatch(_nomorKtp.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nomor KTP harus 16 digit angka.')),
      );
      return;
    }
    if (_fotoKtp == null || _fotoNib == null || _fotoToko == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto KTP, NIB, dan depan toko wajib diunggah.'),
        ),
      );
      return;
    }
    // Cek ukuran file di client (backend menolak > 5 MB per file).
    final photos = {
      'foto_ktp': _fotoKtp,
      'foto_nib': _fotoNib,
      'foto_toko': _fotoToko,
      'foto_toko_2': _fotoToko2,
      'foto_toko_3': _fotoToko3,
    };
    for (final entry in photos.entries) {
      final file = entry.value;
      if (file == null) continue;
      // Retry: file kamera/galeri kadang belum siap dibaca sepersekian
      // detik setelah dipilih (terutama submit langsung).
      final size = await _readFileSize(file);
      if (size == null) {
        // File tidak terbaca lagi (mis. cache HP terhapus setelah dipilih).
        // Di mobile: minta pilih ulang foto tersebut (kalau diteruskan,
        // upload crash PathNotFoundException tanpa nama field).
        // Di web: blob tidak selalu bisa dicek ukurannya → biarkan server
        // memvalidasi.
        if (!kIsWeb) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${_photoLabels[entry.key]} tidak terbaca, pilih ulang '
                'foto tersebut lalu submit kembali.',
              ),
            ),
          );
          return;
        }
        continue;
      }
      if (size > _maxPhotoBytes) {
        if (!mounted) return;
        final mb = (size / (1024 * 1024)).toStringAsFixed(1);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_photoLabels[entry.key]} kebesaran ($mb MB, maksimal 5 MB). '
              'Pilih foto lain atau kecilkan dulu.',
            ),
          ),
        );
        return;
      }
    }
    if (!mounted) return;

    context.read<AuthBloc>().add(
      MitraRegisterSubmitted(
        fields: {
          'name': _name.text.trim(),
          'email': _email.text.trim(),
          'phone': _phone.text.trim(),
          'password': _password.text,
          'password_confirmation': _passwordConfirm.text,
          'city': _city.text.trim(),
          'district': _district.text.trim(),
          'sub_district': _subDistrict.text.trim(),
          'rt': _rt.text.trim(),
          'rw': _rw.text.trim(),
          'nama_usaha': _namaUsaha.text.trim(),
          'jenis_usaha': _jenisUsaha.text.trim(),
          'alamat_usaha': _alamatUsaha.text.trim(),
          'usaha_kelurahan': _usahaKelurahan.text.trim(),
          'usaha_kecamatan': _usahaKecamatan.text.trim(),
          'usaha_kota': _usahaKota.text.trim(),
          'usaha_provinsi': _usahaProvinsi.text.trim(),
          'usaha_kode_pos': _usahaKodePos.text.trim(),
          'nomor_ktp': _nomorKtp.text.trim(),
          'nomor_nib': _nomorNib.text.trim(),
          'nama_bank': _namaBank.text.trim(),
          'nomor_rekening': _nomorRekening.text.trim(),
          'nama_pemilik_rekening': _namaPemilikRekening.text.trim(),
        },
        files: {
          'foto_ktp': _fotoKtp,
          'foto_nib': _fotoNib,
          'foto_toko': _fotoToko,
          'foto_toko_2': _fotoToko2,
          'foto_toko_3': _fotoToko3,
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.message != curr.message ||
          prev.fieldErrors != curr.fieldErrors,
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          // Sukses: salinan foto sudah terkirim, hapus agar tak menumpuk.
          // Token tersimpan; SessionGate mengarahkan ke dashboard merchant.
          for (final f in [
            _fotoKtp,
            _fotoNib,
            _fotoToko,
            _fotoToko2,
            _fotoToko3,
          ]) {
            unawaited(discardPersistedPhoto(f));
          }
          Navigator.popUntil(context, (r) => r.isFirst);
        } else if (state.status == AuthStatus.unauthenticated &&
            (state.message != null || state.fieldErrors.isNotEmpty)) {
          if (state.fieldErrors.isNotEmpty) {
            // Rincian per field (ukuran file, format, duplikat, dsb).
            showValidationErrorSheet(
              context,
              title: 'Pendaftaran belum berhasil',
              errors: state.fieldErrors,
            );
          } else {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.message!)));
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4FAF5),
        appBar: AppBar(
          title: const Text('Daftar Mitra UMKM'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.black87,
          actions: [
            // Helper dev: isi form otomatis dengan data valid + unik.
            // Hanya muncul di debug build, tidak ada di release.
            if (kDebugMode)
              IconButton(
                tooltip: 'Isi otomatis (dev)',
                onPressed: _seedForm,
                icon: const Icon(Icons.auto_fix_high),
              ),
          ],
        ),
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final loading = state.status == AuthStatus.loading;
            final fieldErrors = state.fieldErrors;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Akun Anda langsung aktif, tetapi toko baru bisa menerima voucher setelah admin memverifikasi.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  _section('Data Owner', [
                    _field(
                      _name,
                      'Nama lengkap',
                      error: fieldErrors['name']?.firstOrNull,
                    ),
                    _field(
                      _email,
                      'Email',
                      keyboard: TextInputType.emailAddress,
                      error: fieldErrors['email']?.firstOrNull,
                    ),
                    _field(
                      _phone,
                      'No HP (08... / +62...)',
                      keyboard: TextInputType.phone,
                      error: fieldErrors['phone']?.firstOrNull,
                    ),
                    _field(
                      _password,
                      'Kata sandi (min 8)',
                      password: true,
                      obscure: _obscurePassword,
                      onToggle: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    _field(
                      _passwordConfirm,
                      'Konfirmasi kata sandi',
                      password: true,
                      obscure: _obscureConfirm,
                      onToggle: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    Row(
                      children: [
                        Expanded(child: _field(_city, 'Kota')),
                        const SizedBox(width: 10),
                        Expanded(child: _field(_district, 'Kecamatan')),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(child: _field(_subDistrict, 'Kelurahan')),
                        const SizedBox(width: 10),
                        Expanded(child: _field(_rt, 'RT')),
                        const SizedBox(width: 10),
                        Expanded(child: _field(_rw, 'RW')),
                      ],
                    ),
                  ]),
                  _section('Data Toko', [
                    _field(_namaUsaha, 'Nama usaha'),
                    _field(_jenisUsaha, 'Jenis usaha (cth. Kedai Kopi)'),
                    _field(_alamatUsaha, 'Alamat usaha', maxLines: 2),
                    Row(
                      children: [
                        Expanded(child: _field(_usahaKelurahan, 'Kel. usaha')),
                        const SizedBox(width: 10),
                        Expanded(child: _field(_usahaKecamatan, 'Kec. usaha')),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(child: _field(_usahaKota, 'Kota usaha')),
                        const SizedBox(width: 10),
                        Expanded(child: _field(_usahaProvinsi, 'Provinsi')),
                      ],
                    ),
                    _field(
                      _usahaKodePos,
                      'Kode pos (opsional)',
                      keyboard: TextInputType.number,
                    ),
                  ]),
                  _section('Dokumen', [
                    _field(
                      _nomorKtp,
                      'Nomor KTP (16 digit)',
                      keyboard: TextInputType.number,
                      error: fieldErrors['nomor_ktp']?.firstOrNull,
                    ),
                    _field(
                      _nomorNib,
                      'Nomor NIB',
                      error: fieldErrors['nomor_nib']?.firstOrNull,
                    ),
                    _photoTile('Foto KTP *', _fotoKtp, 'foto_ktp'),
                    _photoTile('Foto NIB *', _fotoNib, 'foto_nib'),
                    _photoTile('Foto depan toko *', _fotoToko, 'foto_toko'),
                    _photoTile(
                      'Foto toko 2 (opsional)',
                      _fotoToko2,
                      'foto_toko_2',
                    ),
                    _photoTile(
                      'Foto toko 3 (opsional)',
                      _fotoToko3,
                      'foto_toko_3',
                    ),
                  ]),
                  _section('Rekening Pencairan', [
                    _field(
                      _namaBank,
                      'Nama bank (cth. Bank BCA)',
                      error: fieldErrors['nama_bank']?.firstOrNull,
                    ),
                    _field(
                      _nomorRekening,
                      'Nomor rekening',
                      keyboard: TextInputType.number,
                    ),
                    _field(_namaPemilikRekening, 'Nama pemilik rekening'),
                  ]),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                        elevation: 0,
                      ),
                      child: loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Daftar & Ajukan Verifikasi',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String hint, {
    TextInputType? keyboard,
    bool password = false,
    bool obscure = false,
    VoidCallback? onToggle,
    int maxLines = 1,
    String? error,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: controller,
          keyboardType: keyboard,
          obscureText: password && obscure,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            filled: true,
            fillColor: const Color(0xFFF4FAF5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            suffixIcon: password
                ? IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                      size: 18,
                      color: Colors.grey.shade600,
                    ),
                    onPressed: onToggle,
                  )
                : null,
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(
            error,
            style: const TextStyle(fontSize: 11, color: Color(0xFFC62828)),
          ),
        ],
      ],
    );
  }

  Widget _photoTile(String label, XFile? file, String field) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _pickPhoto(field),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF4FAF5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: file == null
                ? Colors.grey.shade300
                : _green.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: file == null
                  ? const Icon(
                      Icons.add_a_photo_outlined,
                      color: Colors.black45,
                    )
                  : const Icon(Icons.check_circle, color: _green),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    file == null
                        ? 'Ketuk untuk ambil foto'
                        : file.path.split(RegExp(r'[\\/]')).last,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
