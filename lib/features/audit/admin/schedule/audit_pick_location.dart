import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color _kPrimary   = Color(0xFF8B5CF6);
const Color _kPrimaryLt = Color(0xFFEDE9FE);
const Color _kTextSub   = Color(0xFF64748B);
const Color _kNameColor = Color(0xFF1D72F3);

class _JabatanStyle {
  final Color color;
  final IconData icon;
  const _JabatanStyle(this.color, this.icon);
}

_JabatanStyle _jabatanStyle(String? jabatan) {
  final j = (jabatan ?? '').toLowerCase();
  if (j.contains('eksekutif')) {
    return const _JabatanStyle(Color(0xFFDC2626), Icons.workspace_premium_rounded);
  } else if (j.contains('manager')) {
    return const _JabatanStyle(Color(0xFF2563EB), Icons.badge_rounded);
  } else if (j.contains('kasie')) {
    return const _JabatanStyle(Color(0xFF7C3AED), Icons.supervisor_account_rounded);
  } else if (j.contains('hrd')) {
    return const _JabatanStyle(Color(0xFFF59E0B), Icons.groups_2_rounded);
  }
  return const _JabatanStyle(Color(0xFF64748B), Icons.person_rounded);
}

bool _shouldShowJabatan(String? jabatan) {
  if (jabatan == null || jabatan.trim().isEmpty) return false;
  return !jabatan.toLowerCase().contains('admin');
}

const List<Color> kAuditLevelColors = [
  Color(0xFF10B981),
  Color(0xFF6366F1),
  Color(0xFFFBBF24),
  Color(0xFFF472B6),
];

const List<IconData> kAuditLevelIcons = [
  Icons.location_city_rounded,
  Icons.business_rounded,
  Icons.layers_outlined,
  Icons.place_rounded,
];

const List<String> kAuditLevelKeys = ['lokasi', 'unit', 'subunit', 'area'];

class AuditLocationResult {
  final String levelType;
  final String idRef;
  final String locationName;
  const AuditLocationResult({
    required this.levelType,
    required this.idRef,
    required this.locationName,
  });
}

class AuditUsedLocation {
  final String levelType;
  final String idRef;
  final String auditorName;
  const AuditUsedLocation({
    required this.levelType,
    required this.idRef,
    required this.auditorName,
  });
}

Future<AuditLocationResult?> showAuditLocationPicker({
  required BuildContext context,
  required String lang,
  required Map<String, dynamic> auditor,
  required List<AuditUsedLocation> usedLocations,
}) {
  return showDialog<AuditLocationResult>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (ctx) => _AuditLocationPickerDialog(
      lang: lang,
      auditor: auditor,
      usedLocations: usedLocations,
    ),
  );
}

class _AuditLocationPickerDialog extends StatefulWidget {
  final String lang;
  final Map<String, dynamic> auditor;
  final List<AuditUsedLocation> usedLocations;

  const _AuditLocationPickerDialog({
    required this.lang,
    required this.auditor,
    required this.usedLocations,
  });

  @override
  State<_AuditLocationPickerDialog> createState() =>
      _AuditLocationPickerDialogState();
}

class _AuditLocationPickerDialogState
    extends State<_AuditLocationPickerDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _supabase = Supabase.instance.client;

  final Map<int, List<Map<String, dynamic>>> _data = {};
  final Map<int, bool> _loading = {0: true, 1: true, 2: true, 3: true};
  final Map<int, int> _currentPage = {0: 1, 1: 1, 2: 1, 3: 1};

  static const int _kPerPage = 5;

  int _totalPagesFor(int index) {
    final len = (_data[index] ?? []).length;
    final p = (len / _kPerPage).ceil();
    return p < 1 ? 1 : p;
  }

  List<Map<String, dynamic>> _pageItemsFor(int index) {
    final list = _data[index] ?? [];
    final page = _currentPage[index] ?? 1;
    final start = (page - 1) * _kPerPage;
    if (start >= list.length) return [];
    final end = (start + _kPerPage) > list.length ? list.length : start + _kPerPage;
    return list.sublist(start, end);
  }

  void _goToPageFor(int index, int page) => setState(() => _currentPage[index] = page);

  String? _selectedLevel;
  String? _selectedId;
  String? _selectedName;

  static const _tables   = ['lokasi', 'unit', 'subunit', 'area'];
  static const _idCols   = ['id_lokasi', 'id_unit', 'id_subunit', 'id_area'];
  static const _nameCols = ['nama_lokasi', 'nama_unit', 'nama_subunit', 'nama_area'];
  static const _fkHints = [
    'fk_lokasi_pic',
    'fk_unit_pic',
    'fk_subunit_pic',
    'fk_area_pic',
  ];

  String _t(String en, String id, String zh) {
    if (widget.lang == 'EN') return en;
    if (widget.lang == 'ZH') return zh;
    return id;
  }

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    for (int i = 0; i < 4; i++) {
      _loadTab(i);
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTab(int index) async {
    final table   = _tables[index];
    final idCol   = _idCols[index];
    final nameCol = _nameCols[index];

    List<dynamic> raw;
    try {
      raw = await _supabase
          .from(table)
          .select(
              '$idCol, $nameCol, id_pic, User_PIC:User!${_fkHints[index]}(nama, gambar_user)')
          .order(nameCol);
    } catch (_) {
      try {
        raw = await _supabase.from(table).select('$idCol, $nameCol').order(nameCol);
      } catch (_) {
        raw = [];
      }
    }

    if (!mounted) return;
    setState(() {
      _data[index]    = List<Map<String, dynamic>>.from(raw);
      _loading[index] = false;
    });
  }

  AuditUsedLocation? _findUsed(String levelType, String idRef) {
    for (final u in widget.usedLocations) {
      if (u.levelType == levelType && u.idRef == idRef) return u;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final auditorName = widget.auditor['nama']?.toString() ?? '-';
    final jabatan = (widget.auditor['jabatan'] as Map<String, dynamic>?)?['nama_jabatan']?.toString();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 480,
        ),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // HEADER
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _kPrimaryLt,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.map_rounded, color: _kPrimary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _t('SELECT AUDIT LOCATION', 'PILIH LOKASI AUDIT', '选择审计位置'),
                        style: GoogleFonts.poppins(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: _kPrimary,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
              // AUDITOR INFO
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: Builder(builder: (context) {
                  final showJabatan = _shouldShowJabatan(jabatan);
                  final jStyle = _jabatanStyle(jabatan);
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _kPrimary.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: _kPrimaryLt,
                          backgroundImage: widget.auditor['gambar_user'] != null
                              ? NetworkImage(widget.auditor['gambar_user'] as String)
                              : null,
                          child: widget.auditor['gambar_user'] == null
                              ? Text(
                                  auditorName.isNotEmpty ? auditorName[0].toUpperCase() : '?',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: _kPrimary),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(auditorName,
                                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: _kNameColor)),
                              if (showJabatan) ...[
                                const SizedBox(height: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: jStyle.color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: jStyle.color.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(jStyle.icon, size: 10, color: jStyle.color),
                                      const SizedBox(width: 4),
                                      Text(jabatan!,
                                          style: GoogleFonts.poppins(
                                              fontSize: 10, fontWeight: FontWeight.w700, color: jStyle.color)),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
              Container(height: 1, color: const Color(0xFFF1F5F9)),
              // TAB BAR SPECIFIC LOCATION LEVEL
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: AnimatedBuilder(
                  animation: _tabCtrl,
                  builder: (context, _) {
                    final labels = [
                      _t('Location', 'Lokasi', '位置'),
                      'Unit',
                      _t('Sub-Unit', 'Sub-Unit', '子单位'),
                      _t('Area', 'Area', '区域'),
                    ];
                    return Row(
                      children: List.generate(4, (index) {
                        final isActive = _tabCtrl.index == index;
                        final color = kAuditLevelColors[index];
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => _tabCtrl.animateTo(index),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isActive ? color : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: isActive ? color : const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(kAuditLevelIcons[index], size: 15, color: isActive ? Colors.white : color),
                                  const SizedBox(height: 3),
                                  Text(labels[index],
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: isActive ? Colors.white : const Color(0xFF475569))),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Container(height: 1, color: const Color(0xFFF1F5F9)),
              // CONTENT
              Expanded(
                child: TabBarView(
                  controller: _tabCtrl,
                  physics: const NeverScrollableScrollPhysics(),
                  children: List.generate(4, _buildTabContent),
                ),
              ),
              Container(height: 1, color: const Color(0xFFF1F5F9)),
              // FOOTER
              Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 14),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _kPrimary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        child: Text(_t('Cancel', 'Batal', '取消'),
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: _kPrimary)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _selectedId == null
                            ? null
                            : () => Navigator.pop(
                                  context,
                                  AuditLocationResult(
                                    levelType: _selectedLevel!,
                                    idRef: _selectedId!,
                                    locationName: _selectedName!,
                                  ),
                                ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade200,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        child: Text(_t('Confirm Assignment', 'Konfirmasi Penugasan', '确认分配'),
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(int index) {
    if (_loading[index] == true) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    }

    final list = _data[index] ?? [];
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/team_illustration.png',
                height: 130,
                errorBuilder: (_, __, ___) => Icon(Icons.location_off_rounded,
                    size: 72, color: kAuditLevelColors[index].withValues(alpha: 0.5)),
              ),
              const SizedBox(height: 14),
              Text(
                _t('No data found', 'Data tidak ditemukan', '未找到数据'),
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: _kTextSub),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            itemCount: _pageItemsFor(index).length,
            itemBuilder: (_, i) => _buildLocationCard(index, _pageItemsFor(index)[i]),
          ),
        ),
        if (list.length > _kPerPage)
          _LocationPageIndicator(
            currentPage: _currentPage[index] ?? 1,
            totalPages: _totalPagesFor(index),
            onPageChanged: (p) => _goToPageFor(index, p),
          ),
      ],
    );
  }

  Widget _buildLocationCard(int levelIdx, Map<String, dynamic> item) {
    final color    = kAuditLevelColors[levelIdx];
    final icon     = kAuditLevelIcons[levelIdx];
    final id       = item[_idCols[levelIdx]]?.toString() ?? '';
    final name     = item[_nameCols[levelIdx]]?.toString() ?? '-';
    final levelKey = _tables[levelIdx];

    final picData  = item['User_PIC'] as Map<String, dynamic>?;
    final picName  = picData?['nama']?.toString();
    final picImage = picData?['gambar_user']?.toString();

    final usedInfo    = _findUsed(levelKey, id);
    final isUsed      = usedInfo != null;
    final isSelected  = _selectedLevel == levelKey && _selectedId == id;

    return GestureDetector(
      onTap: isUsed
          ? null
          : () => setState(() {
                _selectedLevel = levelKey;
                _selectedId    = id;
                _selectedName  = name;
              }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUsed
              ? Colors.grey.shade50
              : isSelected
                  ? color.withValues(alpha: 0.08)
                  : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUsed ? Colors.grey.shade200 : (isSelected ? color : Colors.grey.shade200),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: picImage != null
                  ? Image.network(picImage,
                      width: 56, height: 56, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _levelIconBox(color, icon))
                  : _levelIconBox(color, icon),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: isUsed ? Colors.grey : color)),
                      ),
                      if (isSelected) Icon(Icons.check_circle_rounded, color: color, size: 18),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (isUsed)
                    _pill(
                      icon: Icons.verified_user_rounded,
                      label: '${_t('Assigned', 'Ditugaskan', '已分配')}: ${usedInfo.auditorName}',
                      color: const Color(0xFF10B981),
                    )
                  else
                    _picRow(picName: picName, picImage: picImage, color: color),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _levelIconBox(Color color, IconData icon) => Container(
        width: 56,
        height: 56,
        color: color.withValues(alpha: 0.12),
        alignment: Alignment.center,
        child: Icon(icon, color: color, size: 24),
      );

  Widget _pill({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 9.5, fontWeight: FontWeight.w700, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _picRow({required String? picName, required String? picImage, required Color color}) {
    final hasPic = picName != null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 9,
          backgroundColor: color.withValues(alpha: 0.14),
          backgroundImage: picImage != null ? NetworkImage(picImage) : null,
          child: picImage == null
              ? Icon(hasPic ? Icons.person_rounded : Icons.person_off_rounded,
                  size: 11, color: hasPic ? color : Colors.grey.shade400)
              : null,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: hasPic
              ? RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${_t('PIC', 'PIC', '负责人')} : ',
                        style: GoogleFonts.poppins(
                            fontSize: 9.5, fontWeight: FontWeight.w700, color: Colors.black),
                      ),
                      TextSpan(
                        text: picName,
                        style: GoogleFonts.poppins(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1D72F3)),
                      ),
                    ],
                  ),
                )
              : Text(
                  _t('No PIC', 'Belum ada PIC', '暂无负责人'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: 9.5, fontWeight: FontWeight.w700, color: Colors.grey.shade400),
                ),
        ),
      ],
    );
  }
}

class _LocationPageIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  const _LocationPageIndicator({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  static const Color _mainColor = Color(0xFF6366F1);
  static const int _maxVisibleButtons = 5;

  List<int> _visiblePageNumbers() {
    if (totalPages <= _maxVisibleButtons) {
      return List.generate(totalPages, (i) => i + 1);
    }
    int start = currentPage - 2;
    int end = currentPage + 2;
    if (start < 1) {
      start = 1;
      end = _maxVisibleButtons;
    } else if (end > totalPages) {
      end = totalPages;
      start = totalPages - (_maxVisibleButtons - 1);
    }
    return List.generate(end - start + 1, (i) => start + i);
  }

  @override
  Widget build(BuildContext context) {
    final bool canPrev = currentPage > 1;
    final bool canNext = currentPage < totalPages;
    final pageNumbers = _visiblePageNumbers();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _mainColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            _arrowButton(
              icon: Icons.arrow_back_ios_new_rounded,
              enabled: canPrev,
              onTap: () {
                if (!canPrev) return;
                onPageChanged(currentPage - 1);
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                children: [
                  for (final p in pageNumbers) ...[
                    Expanded(child: _pageNumberButton(p)),
                    if (p != pageNumbers.last) const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            _arrowButton(
              icon: Icons.arrow_forward_ios_rounded,
              enabled: canNext,
              onTap: () {
                if (!canNext) return;
                onPageChanged(currentPage + 1);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageNumberButton(int page) {
    final bool isActive = page == currentPage;
    return GestureDetector(
      onTap: () {
        if (page == currentPage) return;
        onPageChanged(page);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? _mainColor : _mainColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: isActive ? null : Border.all(color: _mainColor.withValues(alpha: 0.25)),
        ),
        child: Text(
          '$page',
          style: GoogleFonts.poppins(color: isActive ? Colors.white : _mainColor, fontWeight: FontWeight.w800, fontSize: 12),
        ),
      ),
    );
  }

  Widget _arrowButton({required IconData icon, required bool enabled, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: enabled ? _mainColor.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 13, color: enabled ? _mainColor : Colors.grey.shade400),
      ),
    );
  }
}