import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../widgets/mission_scan/scan_frame_painter.dart';
import '../widgets/mission_scan/validation_result_sheet.dart';

/// Halaman "Validasi Misi Scan Kamera AI" (frontend-only).
///
/// Dibuka dari tab Misi via tombol "Upload Foto" kartu kategori Sampah.
/// Foto hasil [takePicture] hanya disimpan lokal sementara dan TIDAK
/// diupload — validasi Gemini berjalan server-side (di luar scope file ini).
class MisiScanScreen extends StatefulWidget {
  const MisiScanScreen({super.key, this.missionTitle = 'Misi Sampah'});

  final String missionTitle;

  @override
  State<MisiScanScreen> createState() => _MisiScanScreenState();
}

class _MisiScanScreenState extends State<MisiScanScreen> {
  CameraController? _controller;
  bool _isInitializing = true;
  String? _errorMessage;
  bool _flashOn = false;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _fail('Tidak ada kamera yang tersedia di perangkat ini.');
        return;
      }
      final back = cameras.where(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      final selected = back.isNotEmpty ? back.first : cameras.first;
      final controller = CameraController(
        selected,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _isInitializing = false;
      });
    } on CameraException catch (e) {
      _fail(_cameraErrorText(e));
    } catch (_) {
      _fail('Gagal membuka kamera. Periksa izin kamera lalu coba lagi.');
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
      _isInitializing = false;
    });
  }

  String _cameraErrorText(CameraException e) {
    switch (e.code) {
      case 'CameraAccessDenied':
        return 'Izin kamera ditolak. Aktifkan izin kamera di pengaturan.';
      case 'CameraAccessDeniedWithoutPrompt':
        return 'Izin kamera ditolak permanen. Aktifkan di pengaturan aplikasi.';
      case 'CameraAccessRestricted':
        return 'Akses kamera dibatasi di perangkat ini.';
      default:
        return 'Gagal membuka kamera (${e.code}). Coba lagi.';
    }
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      final next = !_flashOn;
      await controller.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      if (mounted) setState(() => _flashOn = next);
    } catch (_) {
      // Abaikan: tidak semua perangkat mendukung torch saat preview.
    }
  }

  Future<void> _onShutter() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isAnalyzing) {
      return;
    }
    setState(() => _isAnalyzing = true);
    try {
      // Frontend-only: file foto disimpan lokal, belum diupload ke backend.
      await controller.takePicture();
      // Simulasi analisis AI lokal (mock, tanpa backend).
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => ValidationResultSheet(
          onContinue: () {
            Navigator.pop(context); // tutup sheet
            Navigator.pop(context, true); // kembali ke layar Misi
          },
        ),
      );
    } on CameraException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengambil foto. Coba lagi.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.black, body: _buildBody());
  }

  Widget _buildBody() {
    if (_isInitializing) return _buildLoading();
    if (_errorMessage != null || _controller == null) {
      return _buildCameraError();
    }
    return _buildCameraView();
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Color(0xFF2E9E4B)),
          SizedBox(height: 12),
          Text(
            'Membuka kamera...',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraError() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                color: Colors.white54,
                size: 56,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? 'Kamera tidak tersedia.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 20),
              _backPill(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    return Stack(
      children: [
        Positioned.fill(child: _buildPreview()),
        SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              const SizedBox(height: 10),
              _buildTooltip(),
              const Spacer(),
              _buildScanFrame(),
              const Spacer(),
              _buildShutter(),
              const SizedBox(height: 24),
            ],
          ),
        ),
        if (_isAnalyzing) _buildAnalyzingOverlay(),
      ],
    );
  }

  Widget _buildPreview() {
    final controller = _controller!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final previewSize = controller.value.previewSize;
        if (previewSize == null) return CameraPreview(controller);
        return ClipRect(
          child: OverflowBox(
            maxWidth: constraints.maxWidth,
            maxHeight: constraints.maxHeight,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: previewSize.height,
                height: previewSize.width,
                child: CameraPreview(controller),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [_backPill(), _flashButton()],
      ),
    );
  }

  Widget _backPill() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_back, color: Colors.white, size: 16),
            SizedBox(width: 6),
            Text(
              'Kembali ke Misi',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _flashButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _toggleFlash,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              shape: BoxShape.circle,
              border: _flashOn
                  ? Border.all(color: const Color(0xFFFFD54F), width: 1.5)
                  : null,
            ),
            child: Icon(
              _flashOn ? Icons.flash_on : Icons.flash_off,
              color: _flashOn ? const Color(0xFFFFD54F) : Colors.white,
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Flash',
          style: TextStyle(color: Colors.white, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildTooltip() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lightbulb_outline, color: Color(0xFF22C55E), size: 16),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              'Pastikan sampah terpilah terlihat jelas & pencahayaan cukup',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanFrame() {
    final side = MediaQuery.of(context).size.width * 0.68;
    return IgnorePointer(
      child: SizedBox(
        width: side,
        height: side,
        child: CustomPaint(painter: ScanFramePainter()),
      ),
    );
  }

  Widget _buildShutter() {
    return GestureDetector(
      onTap: _isAnalyzing ? null : _onShutter,
      child: Opacity(
        opacity: _isAnalyzing ? 0.6 : 1,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.camera_alt, color: Colors.green[700], size: 28),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyzingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.35),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    color: Color(0xFF22C55E),
                    strokeWidth: 3,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'AI sedang menganalisis foto...',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
