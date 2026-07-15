import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/image_picker_helper.dart';
import '../add_finding_flow_screen.dart';

class CameraWarmupService {
  CameraWarmupService._();
  static final CameraWarmupService instance = CameraWarmupService._();

  CameraController? controller;
  List<CameraDescription>? cameras;
  int selectedCameraIndex = 0;
  bool isWarming = false;

  bool get isReady => controller != null && controller!.value.isInitialized;

  Future<void> warmUp() async {
    if (isReady || isWarming) return;
    isWarming = true;
    try {
      cameras ??= await availableCameras();
      if (cameras == null || cameras!.isEmpty) return;
      final newController = CameraController(
        cameras![selectedCameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
      );
      await newController.initialize();
      controller = newController;
    } catch (e) {
      debugPrint('Error warming up camera: $e');
    } finally {
      isWarming = false;
    }
  }

  CameraController? takeController() {
    final c = controller;
    controller = null;
    return c;
  }

  Future<void> release() async {
    await controller?.dispose();
    controller = null;
  }
}

class CameraFindingScreen extends StatefulWidget {
  final String lang;
  final bool isProMode;
  final bool isVisitorMode;

  final String selectedLocationName;
  final String? selectedLocationId;
  final String? selectedUnitId;
  final String? selectedSubunitId;
  final String? selectedAreaId;
  final VoidCallback? onFindingSaved;
  final String? qrType;
  final String? qrId;

  const CameraFindingScreen({
    super.key,
    required this.lang,
    required this.isProMode,
    required this.isVisitorMode,
    required this.selectedLocationName,
    this.selectedLocationId,
    this.selectedUnitId,
    this.selectedSubunitId,
    this.selectedAreaId,
    this.onFindingSaved,
    this.qrType,
    this.qrId,
  });

  @override
  State<CameraFindingScreen> createState() => _CameraFindingScreenState();
}

class _CameraFindingScreenState extends State<CameraFindingScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;
  bool _flashEnabled = false;
  bool _flashSupported = false;

  // ── State hasil resolve lokasi dari QR (diisi async di background) ──
  String? _resolvedLocationName;
  String? _resolvedLokasiId;
  String? _resolvedUnitId;
  String? _resolvedSubunitId;
  String? _resolvedAreaId;

  bool get _isQrFlow => widget.qrType != null && widget.qrId != null;

  String get _effectiveLocationName {
    if (!_isQrFlow) return widget.selectedLocationName;
    return _resolvedLocationName ?? _txt('resolving_location');
  }

  String? get _effectiveLokasiId => _isQrFlow ? _resolvedLokasiId : widget.selectedLocationId;
  String? get _effectiveUnitId => _isQrFlow ? _resolvedUnitId : widget.selectedUnitId;
  String? get _effectiveSubunitId => _isQrFlow ? _resolvedSubunitId : widget.selectedSubunitId;
  String? get _effectiveAreaId => _isQrFlow ? _resolvedAreaId : widget.selectedAreaId;

  Map<String, String>? _currentLocationBackInfo() {
    String? id;
    String type;
    if (_effectiveAreaId != null) {
      id = _effectiveAreaId;
      type = 'area';
    } else if (_effectiveSubunitId != null) {
      id = _effectiveSubunitId;
      type = 'subunit';
    } else if (_effectiveUnitId != null) {
      id = _effectiveUnitId;
      type = 'unit';
    } else if (_effectiveLokasiId != null) {
      id = _effectiveLokasiId;
      type = 'lokasi';
    } else {
      return null;
    }
    if (id == null) return null;
    return {'action': 'back', 'type': type, 'id': id};
  }

  IconData get _locationLevelIcon {
    final type = widget.qrType;
    if (type != null) {
      switch (type) {
        case 'area': return Icons.place_rounded;
        case 'subunit': return Icons.layers_rounded;
        case 'unit': return Icons.business_rounded;
        default: return Icons.location_city_rounded;
      }
    }
    if (widget.selectedAreaId != null) return Icons.place_rounded;
    if (widget.selectedSubunitId != null) return Icons.layers_rounded;
    if (widget.selectedUnitId != null) return Icons.business_rounded;
    return Icons.location_city_rounded;
  }

  Color get _locationLevelColor {
    final type = widget.qrType;
    if (type != null) {
      switch (type) {
        case 'area': return const Color(0xFFF472B6);
        case 'subunit': return const Color(0xFFFBBF24);
        case 'unit': return const Color(0xFF6366F1);
        default: return const Color(0xFF10B981);
      }
    }
    if (widget.selectedAreaId != null) return const Color(0xFFF472B6);
    if (widget.selectedSubunitId != null) return const Color(0xFFFBBF24);
    if (widget.selectedUnitId != null) return const Color(0xFF6366F1);
    return const Color(0xFF10B981);
  }

  String _txt(String key) {
    const Map<String, Map<String, String>> texts = {
      'EN': {
        'choose_location': 'Choose Finding Location',
        'resolving_location': 'Resolving location...',
        'error_title': 'Location Failed',
        'location_not_found': 'Specific location not found.',
        'close_button': 'Close',
        'preparing_camera': 'Preparing camera...',
      },
      'ID': {
        'choose_location': 'Pilih Lokasi Temuan',
        'resolving_location': 'Memuat lokasi...',
        'error_title': 'Gagal Memuat Lokasi',
        'location_not_found': 'Lokasi spesifik tidak ditemukan.',
        'close_button': 'Tutup',
        'preparing_camera': 'Menyiapkan kamera...',
      },
      'ZH': {
        'choose_location': '选择发现位置',
        'resolving_location': '正在加载位置...',
        'error_title': '加载位置失败',
        'location_not_found': '未找到特定位置。',
        'close_button': '关闭',
        'preparing_camera': '正在准备相机...',
      },
    };
    return texts[widget.lang]?[key] ?? texts['ID']![key]!;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    if (_isQrFlow) _resolveQrLocation();
  }

  Future<void> _resolveQrLocation() async {
    final supabase = Supabase.instance.client;
    final type = widget.qrType!;
    final id = widget.qrId!;

    try {
      String locationName = '';
      String? idL, idU, idS, idA;

      if (type == 'lokasi') {
        final data = await supabase.from('lokasi')
            .select('id_lokasi, nama_lokasi').eq('id_lokasi', id).single();
        idL = data['id_lokasi']?.toString();
        locationName = data['nama_lokasi'] ?? '';
      } else if (type == 'unit') {
        final data = await supabase.from('unit')
            .select('id_unit, nama_unit, lokasi(id_lokasi, nama_lokasi)')
            .eq('id_unit', id).single();
        idU = data['id_unit']?.toString();
        final lokasi = data['lokasi'];
        idL = lokasi?['id_lokasi']?.toString();
        locationName = '${lokasi?['nama_lokasi'] ?? ''} / ${data['nama_unit'] ?? ''}';
      } else if (type == 'subunit') {
        final data = await supabase.from('subunit')
            .select('id_subunit, nama_subunit, unit(id_unit, nama_unit, lokasi(id_lokasi, nama_lokasi))')
            .eq('id_subunit', id).single();
        idS = data['id_subunit']?.toString();
        final unit = data['unit'];
        final lokasi = unit?['lokasi'];
        idU = unit?['id_unit']?.toString();
        idL = lokasi?['id_lokasi']?.toString();
        locationName = '${lokasi?['nama_lokasi'] ?? ''} / ${unit?['nama_unit'] ?? ''} / ${data['nama_subunit'] ?? ''}';
      } else if (type == 'area') {
        final data = await supabase.from('area')
            .select('id_area, nama_area, subunit(id_subunit, nama_subunit, unit(id_unit, nama_unit, lokasi(id_lokasi, nama_lokasi)))')
            .eq('id_area', id).single();
        idA = data['id_area']?.toString();
        final subunit = data['subunit'];
        final unit = subunit?['unit'];
        final lokasi = unit?['lokasi'];
        idS = subunit?['id_subunit']?.toString();
        idU = unit?['id_unit']?.toString();
        idL = lokasi?['id_lokasi']?.toString();
        locationName = '${lokasi?['nama_lokasi'] ?? ''} / ${unit?['nama_unit'] ?? ''} / ${subunit?['nama_subunit'] ?? ''} / ${data['nama_area'] ?? ''}';
      }

      if (!mounted) return;
      setState(() {
        _resolvedLocationName = locationName;
        _resolvedLokasiId = idL;
        _resolvedUnitId = idU;
        _resolvedSubunitId = idS;
        _resolvedAreaId = idA;
      });
    } catch (e) {
      debugPrint('Error resolving QR location: $e');
      if (!mounted) return;
      _showLocationErrorDialog();
    }
  }

  void _showLocationErrorDialog() {
    if (!mounted) return;
    const redColor = Color(0xFFEF4444);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: redColor.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded, color: redColor, size: 36),
                ),
                const SizedBox(height: 18),
                Text(
                  _txt('error_title'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                Text(
                  _txt('location_not_found'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 13.5, color: const Color(0xFF64748B), height: 1.4),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: redColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      Navigator.of(context).pop(null);
                    },
                    child: Text(_txt('close_button'), style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    final warm = CameraWarmupService.instance;

    if (warm.isReady) {
      _cameras = warm.cameras;
      _selectedCameraIndex = warm.selectedCameraIndex;
      _cameraController = warm.takeController();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _flashEnabled = false;
        });
      }
      await _checkFlashSupport();
      return;
    }

    try {
      _cameras = warm.cameras ?? await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        await _setCamera(_selectedCameraIndex);
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> _setCamera(int index) async {
    if (_cameraController != null) await _cameraController!.dispose();
    _cameraController = CameraController(
      _cameras![index],
      ResolutionPreset.high,
      enableAudio: false,
    );
    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _flashEnabled = false;
        });
      }
      await _checkFlashSupport();
    } on CameraException catch (e) {
      debugPrint('Error setting camera: ${e.code}\n${e.description}');
    }
  }

  void _switchCamera() {
    if (_cameras == null || _cameras!.length < 2) return;
    setState(() {
      _isCameraInitialized = false;
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    });
    _setCamera(_selectedCameraIndex);
  }

  Future<void> _checkFlashSupport() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    try {
      await _cameraController!.setFlashMode(FlashMode.off);
      if (mounted) setState(() => _flashSupported = true);
    } catch (_) {
      if (mounted) setState(() => _flashSupported = false);
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || !_flashSupported) return;
    try {
      final next = _flashEnabled ? FlashMode.off : FlashMode.torch;
      await _cameraController!.setFlashMode(next);
      if (mounted) setState(() => _flashEnabled = !_flashEnabled);
    } catch (_) {}
  }

  Future<void> _navigateToForm(XFile imageXFile) async {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddFindingFlowScreen(
          lang: widget.lang,
          isProMode: widget.isProMode,
          isVisitorMode: widget.isVisitorMode,
          initialImageXFile: imageXFile,
          preSelectedLocationName: _effectiveLocationName,
          preSelectedLocationId: _effectiveLokasiId,
          preSelectedUnitId: _effectiveUnitId,
          preSelectedSubunitId: _effectiveSubunitId,
          preSelectedAreaId: _effectiveAreaId,
          onFindingSaved: widget.onFindingSaved,
        ),
      ),
    ).then((result) {
      if (!mounted) return;
      if (result == true) Navigator.pop(context, true);
    });
  }

  Future<void> _takePicture() async {
    if (!_isCameraInitialized || _cameraController == null || _cameraController!.value.isTakingPicture) return;
    try {
      final XFile picture = await _cameraController!.takePicture();
      await _navigateToForm(picture);
    } on CameraException catch (e) {
      debugPrint('Error taking picture: ${e.code}\n${e.description}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.description}')),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await ImagePickerHelper.pickImageFromGallery();
      if (image == null) return;
      await _navigateToForm(image);
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Widget _buildLoadingView() {
    const accentColor = Color(0xFF1D72F3);
    return Container(
      color: Colors.black,
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOut,
          builder: (context, opacity, child) => Opacity(opacity: opacity, child: child),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: Lottie.asset(
                  'assets/lottie/camera_loading.json',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _PulsingText(text: _txt('preparing_camera'), color: accentColor),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool ready = _isCameraInitialized && _cameraController != null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (ready) CameraPreview(_cameraController!) else _buildLoadingView(),

          if (ready) ...[
            // TOP BAR
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Row(
                    children: [
                      // BACK BUTTON
                      _CameraIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.pop(context, _currentLocationBackInfo()),
                        size: 52,
                      ),
                      const SizedBox(width: 10),
                      // SPESIFIC LOCATION LABEL
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 13),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha:0.6),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: _locationLevelColor.withValues(alpha:0.6), width: 1.2),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_locationLevelIcon,
                                  color: _locationLevelColor, size: 20),
                              const SizedBox(width: 8),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.center,
                                  child: Text(
                                      _effectiveLocationName.toUpperCase(),
                                      style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      letterSpacing: 0.5,
                                    ),
                                    maxLines: 1,
                                    softWrap: false,
                                    overflow: TextOverflow.visible,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // FLASH BUTTON
                      _FlashButton(
                        supported: _flashSupported && _isCameraInitialized,
                        enabled: _flashEnabled,
                        onTap: _toggleFlash,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // BOTTOM CONTROLS
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha:0.75),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _CameraIconButton(
                        icon: Icons.photo_library_rounded,
                        onTap: _pickFromGallery,
                        size: 52,
                      ),
                      GestureDetector(
                        onTap: _takePicture,
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                      _CameraIconButton(
                        icon: Icons.flip_camera_ios_rounded,
                        onTap: _switchCamera,
                        size: 52,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CameraIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const _CameraIconButton({
    required this.icon,
    required this.onTap,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha:0.5),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha:0.2), width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.45),
      ),
    );
  }
}

class _FlashButton extends StatelessWidget {
  final bool supported;
  final bool enabled;
  final VoidCallback onTap;

  const _FlashButton({
    required this.supported,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: supported ? (enabled ? 'Flash On' : 'Flash Off') : 'Flash N/A',
      child: GestureDetector(
        onTap: supported ? onTap : null,
        child: Opacity(
          opacity: supported ? 1.0 : 0.35,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: enabled
                  ? Colors.yellow.withValues(alpha:0.20)
                  : Colors.black.withValues(alpha:0.50),
              shape: BoxShape.circle,
              border: Border.all(
                color: enabled
                    ? Colors.yellow
                    : Colors.white.withValues(alpha:0.2),
                width: 1.5,
              ),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: Colors.yellow.withValues(alpha:0.30),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              enabled ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: enabled ? Colors.yellow : Colors.white,
              size: 52 * 0.45,
            ),
          ),
        ),
      ),
    );
  }
}

class _PulsingText extends StatefulWidget {
  final String text;
  final Color color;

  const _PulsingText({required this.text, required this.color});

  @override
  State<_PulsingText> createState() => _PulsingTextState();
}

class _PulsingTextState extends State<_PulsingText> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Text(
        widget.text,
        style: GoogleFonts.poppins(
          color: widget.color,
          fontWeight: FontWeight.w600,
          fontSize: 13,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}