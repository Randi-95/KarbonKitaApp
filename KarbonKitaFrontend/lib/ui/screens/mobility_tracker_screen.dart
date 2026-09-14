import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../widgets/mobility/mobility_stats_sheet.dart';

/// Layar pelacakan Misi Mobilitas (frontend-only).
///
/// Tanggung jawab file ini:
/// 1. Menampilkan peta `flutter_map` + OpenStreetMap.
/// 2. Meminta izin lokasi & menjalankan stream GPS real-time.
/// 3. Menghitung durasi lokal ([secondsElapsed]) dan akumulasi jarak
///    ([totalDistanceInKm]) dari titik-titik [routePoints].
/// 4. Menyusun payload JSON kontrak backend saat tombol Selesai ditekan.
///
/// TIDAK dilakukan di sini (tanggung jawab Backend): validasi kecepatan,
/// anti-cheat, penghematan karbon, dan perhitungan poin.
class MobilityTrackerScreen extends StatefulWidget {
  const MobilityTrackerScreen({
    super.key,
    this.missionTitle = 'Pejuang Pedal 2Km',
    this.activityType = 'cycling',
    this.missionId,
  });

  final String missionTitle;
  final String activityType;
  final int? missionId;

  @override
  State<MobilityTrackerScreen> createState() => _MobilityTrackerScreenState();
}

class _MobilityTrackerScreenState extends State<MobilityTrackerScreen> {
  static const _fallbackCenter = LatLng(-7.28, 112.79);

  /// Batas akurasi GPS (meter). Fix dengan akurasi lebih buruk dibuang —
  /// tidak masuk rute, tidak nambah jarak, tidak bikin garis.
  static const double _accuracyThresholdM = 30;

  /// Warm-up: kunci titik start setelah 3 fix bagus berurutan yang
  /// saling berdekatan. Mencegah lonjakan awal (mis. langsung 12 KM).
  static const int _warmupRequired = 3;
  static const double _warmupRadiusM = 50;

  /// Cap absolut per-segmen (meter). Lompatan > ini dianggap glitch
  /// (teleport GPS) dan dibuang agar garis tidak melintang kota.
  /// Validasi kecepatan/anti-cheat tetap urusan backend.
  static const double _maxSegmentM = 100;

  final MapController _mapController = MapController();
  final Distance _distance = const Distance();

  // ---- Required state (kontrak tugas) ----
  late String activityType;
  double totalDistanceInKm = 0;
  int secondsElapsed = 0;
  final List<LatLng> routePoints = [];

  Timer? _timer;
  StreamSubscription<Position>? _positionSub;
  LatLng? _currentPosition;
  bool _isPaused = false;
  bool _isInitializing = true;
  bool _isFinished = false;
  String? _errorMessage;

  /// true setelah titik start dikunci (GPS akurat). Sebelum itu UI tetap
  /// 00:00:00 / 0.00 KM tanpa garis hijau.
  bool _startLocked = false;
  final List<LatLng> _warmupFixes = [];

  @override
  void initState() {
    super.initState();
    activityType = widget.activityType;
    _initTracking();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionSub?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initTracking() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _fail('GPS tidak aktif. Aktifkan layanan lokasi lalu coba lagi.');
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      _fail('Izin lokasi ditolak. Tracker membutuhkan akses lokasi.');
      return;
    }
    if (permission == LocationPermission.deniedForever) {
      _fail('Izin lokasi ditolak permanen. Aktifkan di pengaturan aplikasi.');
      return;
    }

    // Tampilkan peta langsung (posisi fallback) lalu kunci start hanya
    // setelah GPS akurat. Timer + akumulasi jarak jalan setelah lock,
    // sehingga halaman selalu mulai dari 0.00 KM tanpa garis hijau.
    if (mounted) {
      setState(() {
        _currentPosition = _fallbackCenter;
        _isInitializing = false;
      });
    }
    _startStream();

    try {
      final first = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      _handleRawFix(LatLng(first.latitude, first.longitude), first.accuracy);
    } catch (_) {
      // Abaikan — stream yang akan mengunci start saat GPS sudah bagus.
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
      _isInitializing = false;
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isPaused || _isFinished || !mounted) return;
      setState(() => secondsElapsed++);
    });
  }

  void _startStream() {
    _positionSub?.cancel();
    // distanceFilter kecil agar garis hijau tumbuh realtime mengikuti
    // gerakan pengguna. Payload tetap kecil untuk misi 1-2 KM.
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(_onPosition, onError: (_) {});
  }

  void _onPosition(Position position) {
    if (_isPaused || _isFinished || !mounted) return;
    _handleRawFix(
      LatLng(position.latitude, position.longitude),
      position.accuracy,
    );
  }

  /// Satu-satunya pintu masuk titik GPS mentah — dipakai baik oleh
  /// `getCurrentPosition` maupun stream. Menjamin:
  /// 1. Mulai dari 0 (start dikunci setelah warm-up akurat).
  /// 2. Titik akurasi buruk dibuang.
  /// 3. Lompatan teleport dibuang (tidak bikin garis melintang).
  void _handleRawFix(LatLng point, double accuracy) {
    if (_isPaused || _isFinished || !mounted) return;
    if (accuracy <= 0 || accuracy > _accuracyThresholdM) return;

    if (!_startLocked) {
      _warmupFixes.add(point);
      if (_warmupFixes.length > _warmupRequired) {
        _warmupFixes.removeAt(0);
      }
      // Update marker biru agar user tahu GPS sudah dapat sinyal,
      // tapi JANGAN tambah routePoints (belum ada garis hijau).
      setState(() => _currentPosition = point);
      if (_warmupFixes.length == _warmupRequired &&
          _warmupClustered(_warmupFixes)) {
        setState(() {
          _startLocked = true;
          routePoints.add(point);
          _currentPosition = point;
        });
        _mapController.move(point, 16);
        _startTimer();
      }
      return;
    }

    final last = routePoints.isNotEmpty ? routePoints.last : _currentPosition;
    if (last == null) {
      setState(() {
        routePoints.add(point);
        _currentPosition = point;
      });
      return;
    }
    final segmentM = _distance.as(LengthUnit.Meter, last, point);
    if (segmentM > _maxSegmentM) return; // teleport/glitch GPS — buang.
    if (segmentM < 1) {
      // Terlalu kecil (noise diam di tempat): update marker saja.
      setState(() => _currentPosition = point);
      return;
    }
    setState(() {
      totalDistanceInKm += segmentM / 1000;
      routePoints.add(point);
      _currentPosition = point;
    });
    _mapController.move(point, _mapController.camera.zoom);
  }

  bool _warmupClustered(List<LatLng> fixes) {
    for (var i = 1; i < fixes.length; i++) {
      if (_distance.as(LengthUnit.Meter, fixes.first, fixes[i]) >
          _warmupRadiusM) {
        return false;
      }
    }
    return true;
  }

  void _togglePause() {
    if (_isInitializing || _isFinished || !_startLocked) return;
    setState(() => _isPaused = !_isPaused);
    if (_isPaused) {
      _timer?.cancel();
      _positionSub?.pause();
    } else {
      _startTimer();
      _positionSub?.resume();
    }
  }

  /// Menyusun payload persis sesuai kontrak backend.
  Map<String, dynamic> _buildPayload() {
    return {
      'activity_type': activityType,
      'distance_km': double.parse(totalDistanceInKm.toStringAsFixed(2)),
      'duration_seconds': secondsElapsed,
      'gps_coordinates_path': routePoints
          .map((p) => {'lat': p.latitude, 'lng': p.longitude})
          .toList(),
    };
  }

  Future<void> _onFinish() async {
    if (_isInitializing || _isFinished) return;
    if (!_startLocked || routePoints.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tunggu sinyal GPS akurat dulu sebelum selesai.'),
        ),
      );
      return;
    }
    setState(() => _isFinished = true);
    _timer?.cancel();
    await _positionSub?.cancel();

    final payload = _buildPayload();
    debugPrint('mobility-sync payload: ${jsonEncode(payload)}');
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PayloadSheet(
        payload: payload,
        onClose: () {
          Navigator.pop(context);
          Navigator.pop(context, payload);
        },
      ),
    );
    if (mounted) setState(() => _isFinished = false);
    // Lanjutkan sesi setelah sheet ditutup (kecuali user memilih kembali).
    if (_startLocked) _startTimer();
    _startStream();
  }

  String _formatDuration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _recenter() {
    final target = _currentPosition;
    if (target != null) _mapController.move(target, 16);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      body: _isInitializing
          ? const _LoadingView()
          : _errorMessage != null
          ? _ErrorView(message: _errorMessage!, onBack: _onBack)
          : _TrackerView(
              mapController: _mapController,
              routePoints: routePoints,
              currentPosition: _currentPosition,
              durationText: _formatDuration(secondsElapsed),
              distanceText: '${totalDistanceInKm.toStringAsFixed(2)} KM',
              isPaused: _isPaused,
              isWaitingGps: !_startLocked,
              onBack: _onBack,
              onRecenter: _recenter,
              onPauseResume: _togglePause,
              onFinish: _onFinish,
            ),
    );
  }

  void _onBack() => Navigator.pop(context);
}

class _TrackerView extends StatelessWidget {
  const _TrackerView({
    required this.mapController,
    required this.routePoints,
    required this.currentPosition,
    required this.durationText,
    required this.distanceText,
    required this.isPaused,
    this.isWaitingGps = false,
    required this.onBack,
    required this.onRecenter,
    required this.onPauseResume,
    required this.onFinish,
  });

  final MapController mapController;
  final List<LatLng> routePoints;
  final LatLng? currentPosition;
  final String durationText;
  final String distanceText;
  final bool isPaused;
  final bool isWaitingGps;
  final VoidCallback onBack;
  final VoidCallback onRecenter;
  final VoidCallback onPauseResume;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: _MapView(
            mapController: mapController,
            routePoints: routePoints,
            currentPosition: currentPosition,
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _CircleButton(icon: Icons.arrow_back, onTap: onBack),
                const Spacer(),
              ],
            ),
          ),
        ),
        Positioned(
          right: 16,
          top: MediaQuery.of(context).size.height * 0.42,
          child: _CircleButton(
            icon: Icons.my_location,
            iconColor: const Color(0xFF22C55E),
            onTap: onRecenter,
          ),
        ),
        if (isWaitingGps)
          Positioned(
            left: 16,
            right: 16,
            top: MediaQuery.of(context).size.height * 0.12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Mencari sinyal GPS akurat… tetap di tempat.',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Align(
          alignment: Alignment.bottomCenter,
          child: MobilityStatsSheet(
            durationText: durationText,
            distanceText: distanceText,
            isPaused: isPaused,
            onPauseResume: onPauseResume,
            onFinish: onFinish,
          ),
        ),
      ],
    );
  }
}

class _MapView extends StatelessWidget {
  const _MapView({
    required this.mapController,
    required this.routePoints,
    required this.currentPosition,
  });

  final MapController mapController;
  final List<LatLng> routePoints;
  final LatLng? currentPosition;

  @override
  Widget build(BuildContext context) {
    final center =
        currentPosition ??
        (routePoints.isNotEmpty
            ? routePoints.first
            : _MobilityTrackerScreenState._fallbackCenter);
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(initialCenter: center, initialZoom: 16),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.karbonkita.app',
        ),
        if (routePoints.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePoints,
                color: const Color(0xFF22C55E),
                strokeWidth: 5,
              ),
            ],
          ),
        if (currentPosition != null)
          MarkerLayer(
            markers: [
              Marker(
                point: currentPosition!,
                width: 36,
                height: 36,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const CircleAvatar(backgroundColor: Color(0xFF2196F3)),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Color(0xFF2E9E4B)),
          SizedBox(height: 12),
          Text(
            'Mengaktifkan GPS...',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onBack});

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_off_outlined,
                size: 56,
                color: Colors.grey,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onBack,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E9E4B),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.iconColor = Colors.black87,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }
}

class _PayloadSheet extends StatelessWidget {
  const _PayloadSheet({required this.payload, required this.onClose});

  final Map<String, dynamic> payload;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    const encoder = JsonEncoder.withIndent('  ');
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Misi selesai! Payload JSON siap.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Frontend-only: data tersimpan lokal, belum dikirim ke backend.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                encoder.convert(payload),
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: jsonEncode(payload)),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Payload JSON disalin.')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Salin JSON'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onClose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Kembali ke Misi'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
