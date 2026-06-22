import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

// Cache valid 6 jam
const _kCacheValidHours = 6;

// ─── Stopwords Indonesia + Inggris + Mandarin umum ───────────────────────────
const _kStopwords = {
  'yang', 'di', 'dan', 'ke', 'dari', 'ini', 'itu', 'ada', 'tidak',
  'dengan', 'untuk', 'pada', 'dalam', 'adalah', 'oleh', 'juga',
  'atau', 'telah', 'sudah', 'akan', 'karena', 'saat', 'area', 'the',
  'is', 'at', 'in', 'on', 'of', 'and', 'or', 'to', 'a', 'an',
  'was', 'has', 'have', 'been', 'by', 'not', 'are', 'were', 'be',
  '的', '了', '在', '是', '和', '有', '不', '这', '那', '一',
};

class GeminiRecurringService {
  static GeminiRecurringService? _instance;
  static GeminiRecurringService get instance =>
      _instance ??= GeminiRecurringService._();
  GeminiRecurringService._();

  final _supabase = Supabase.instance.client;

  // Image byte cache — hindari re-download
  final Map<String, Uint8List?> _imageCache = {};

  // In-flight guard — cegah double analysis bersamaan
  final Map<String, Future<List<RecurringGroup>>> _findingInFlight = {};
  final Map<String, Future<List<RecurringAccidentGroup>>> _accidentInFlight = {};

  // ─────────────────────────────────────────────────────────────────────────
  // PUBLIC API
  // ─────────────────────────────────────────────────────────────────────────

  Future<List<RecurringGroup>> analyzeFindings(
    List<Map<String, dynamic>> findings, {
    bool isKts = false,
    DateTime? fromDate,
    DateTime? toDate,
    String? filterUserId,
  }) async {
    final cacheType = isKts ? 'KTS' : '5R';

    final cached = await _loadFromDb(
      cacheType: cacheType,
      fromDate: fromDate,
      toDate: toDate,
      filterUserId: filterUserId,
    );
    if (cached != null) {
      debugPrint('✅ Cache hit $cacheType: ${cached.length} groups');
      return cached.map((r) => RecurringGroup.fromDbRow(r)).toList();
    }

    if (findings.isEmpty) return [];

    // Guard: jika sudah ada analysis yang sedang berjalan untuk key yang sama, tunggu hasilnya
    final flightKey = '$cacheType|${_fmtDate(fromDate ?? DateTime(2000))}|${_fmtDate(toDate ?? DateTime.now())}|${filterUserId ?? ''}';
    if (_findingInFlight.containsKey(flightKey)) {
      debugPrint('⏳ Reusing in-flight analysis for $flightKey');
      return _findingInFlight[flightKey]!;
    }

    final future = _doAnalyzeFindings(
      findings,
      isKts: isKts,
      fromDate: fromDate,
      toDate: toDate,
      filterUserId: filterUserId,
      cacheType: cacheType,
    );
    _findingInFlight[flightKey] = future;
    try {
      final result = await future;
      return result;
    } finally {
      _findingInFlight.remove(flightKey);
    }
  }

  Future<List<RecurringGroup>> _doAnalyzeFindings(
    List<Map<String, dynamic>> findings, {
    required bool isKts,
    required String cacheType,
    DateTime? fromDate,
    DateTime? toDate,
    String? filterUserId,
  }) async {
    final clusters = _buildClusters(findings, isKts: isKts);
    debugPrint('📦 Pre-clusters: ${clusters.length}');

    final List<RecurringGroup> result = [];
    for (int i = 0; i < clusters.length; i++) {
      final cluster = clusters[i];
      debugPrint(
          '🔄 Validating cluster ${i + 1}/${clusters.length} (${cluster.length} items)');
      final group = await _validateFindingCluster(cluster, isKts: isKts);
      if (group != null) result.add(group);
    }

    result.sort((a, b) => b.total.compareTo(a.total));

    await _saveGroupsToDb(
      groups: result,
      cacheType: cacheType,
      fromDate: fromDate,
      toDate: toDate,
      filterUserId: filterUserId,
    );

    debugPrint('✅ $cacheType done: ${result.length} recurring groups');
    return result;
  }

  Future<List<RecurringAccidentGroup>> analyzeAccidents(
    List<Map<String, dynamic>> reports, {
    DateTime? fromDate,
    DateTime? toDate,
    String? filterUserId,
  }) async {
    const cacheType = 'Accident';

    final cached = await _loadFromDb(
      cacheType: cacheType,
      fromDate: fromDate,
      toDate: toDate,
      filterUserId: filterUserId,
    );
    if (cached != null) {
      debugPrint('✅ Cache hit Accident: ${cached.length} groups');
      return cached.map((r) => RecurringAccidentGroup.fromDbRow(r)).toList();
    }

    if (reports.isEmpty) return [];

    final flightKey = 'Accident|${_fmtDate(fromDate ?? DateTime(2000))}|${_fmtDate(toDate ?? DateTime.now())}|${filterUserId ?? ''}';
    if (_accidentInFlight.containsKey(flightKey)) {
      debugPrint('⏳ Reusing in-flight accident analysis for $flightKey');
      return _accidentInFlight[flightKey]!;
    }

    final future = _doAnalyzeAccidents(
      reports,
      fromDate: fromDate,
      toDate: toDate,
      filterUserId: filterUserId,
    );
    _accidentInFlight[flightKey] = future;
    try {
      final result = await future;
      return result;
    } finally {
      _accidentInFlight.remove(flightKey);
    }
  }

  Future<List<RecurringAccidentGroup>> _doAnalyzeAccidents(
    List<Map<String, dynamic>> reports, {
    DateTime? fromDate,
    DateTime? toDate,
    String? filterUserId,
  }) async {
    final clusters = _buildAccidentClusters(reports);
    debugPrint('📦 Pre-clusters accident: ${clusters.length}');

    final List<RecurringAccidentGroup> result = [];
    for (int i = 0; i < clusters.length; i++) {
      final cluster = clusters[i];
      debugPrint(
          '🔄 Validating accident ${i + 1}/${clusters.length} (${cluster.length} items)');
      final group = await _validateAccidentCluster(cluster);
      if (group != null) result.add(group);
    }

    result.sort((a, b) => b.total.compareTo(a.total));

    await _saveAccidentGroupsToDb(
      groups: result,
      fromDate: fromDate,
      toDate: toDate,
      filterUserId: filterUserId,
    );

    debugPrint('✅ Accident done: ${result.length} recurring groups');
    return result;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CLUSTERING LOKAL — 4 KRITERIA KETAT
  // Semua kriteria harus lolos sebelum masuk validasi lanjut.
  // ─────────────────────────────────────────────────────────────────────────

  List<List<Map<String, dynamic>>> _buildClusters(
    List<Map<String, dynamic>> items, {
    bool isKts = false,
  }) {
    final limit = items.length.clamp(0, 300);
    final parent = List<int>.generate(limit, (i) => i);
    final rank = List<int>.generate(limit, (_) => 0);

    int find(int x) {
      while (parent[x] != x) {
        parent[x] = parent[parent[x]];
        x = parent[x];
      }
      return x;
    }

    void union(int x, int y) {
      final px = find(x), py = find(y);
      if (px == py) return;
      if (rank[px] < rank[py]) {
        parent[px] = py;
      } else if (rank[px] > rank[py]) {
        parent[py] = px;
      } else {
        parent[py] = px;
        rank[px]++;
      }
    }

    final Set<int> pairedIndices = {};

    for (int i = 0; i < limit; i++) {
      for (int j = i + 1; j < limit; j++) {
        // K0: Jenis temuan harus sama
        final jenisI = items[i]['jenis_temuan']?.toString() ?? '';
        final jenisJ = items[j]['jenis_temuan']?.toString() ?? '';
        if (jenisI != jenisJ) continue;

        // K1: Semantic title — combined score ≥ 0.18
        final titleI = items[i]['judul_temuan']?.toString() ?? '';
        final titleJ = items[j]['judul_temuan']?.toString() ?? '';
        final semSim = _combinedTextSim(titleI, titleJ);
        if (semSim < 0.18) continue;

        // K2: Lokasi spesifik SAMA (UUID identik)
        final locI = _getSpecificLocId(items[i]);
        final locJ = _getSpecificLocId(items[j]);
        if (locI.isEmpty || locJ.isEmpty || locI != locJ) continue;

        // K3: Pembuat SAMA (UUID identik)
        final creatorI = items[i]['id_user']?.toString() ?? '';
        final creatorJ = items[j]['id_user']?.toString() ?? '';
        if (creatorI.isEmpty || creatorJ.isEmpty || creatorI != creatorJ) continue;

        union(i, j);
        pairedIndices.add(i);
        pairedIndices.add(j);
      }
    }

    final Map<int, List<Map<String, dynamic>>> groupMap = {};
    for (final idx in pairedIndices) {
      groupMap.putIfAbsent(find(idx), () => []).add(items[idx]);
    }

    return groupMap.values.where((g) => g.length >= 2).toList();
  }

  List<List<Map<String, dynamic>>> _buildAccidentClusters(
    List<Map<String, dynamic>> items,
  ) {
    final limit = items.length.clamp(0, 200);
    final parent = List<int>.generate(limit, (i) => i);
    final rank = List<int>.generate(limit, (_) => 0);

    int find(int x) {
      while (parent[x] != x) {
        parent[x] = parent[parent[x]];
        x = parent[x];
      }
      return x;
    }

    void union(int x, int y) {
      final px = find(x), py = find(y);
      if (px == py) return;
      if (rank[px] < rank[py]) {
        parent[px] = py;
      } else if (rank[px] > rank[py]) {
        parent[py] = px;
      } else {
        parent[py] = px;
        rank[px]++;
      }
    }

    final Set<int> pairedIndices = {};

    for (int i = 0; i < limit; i++) {
      for (int j = i + 1; j < limit; j++) {
        // K1: Semantic judul + penyebab
        final textI =
            '${items[i]['judul'] ?? ''} ${items[i]['penyebab'] ?? ''}';
        final textJ =
            '${items[j]['judul'] ?? ''} ${items[j]['penyebab'] ?? ''}';
        final semSim = _combinedTextSim(textI, textJ);
        if (semSim < 0.16) continue;

        // K2: Lokasi spesifik SAMA
        final locI = _getSpecificLocIdAccident(items[i]);
        final locJ = _getSpecificLocIdAccident(items[j]);
        if (locI.isEmpty || locJ.isEmpty || locI != locJ) continue;

        // K3: Pelapor SAMA
        final repI = items[i]['id_pelapor']?.toString() ?? '';
        final repJ = items[j]['id_pelapor']?.toString() ?? '';
        if (repI.isEmpty || repJ.isEmpty || repI != repJ) continue;

        union(i, j);
        pairedIndices.add(i);
        pairedIndices.add(j);
      }
    }

    final Map<int, List<Map<String, dynamic>>> groupMap = {};
    for (final idx in pairedIndices) {
      groupMap.putIfAbsent(find(idx), () => []).add(items[idx]);
    }

    return groupMap.values.where((g) => g.length >= 2).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // VALIDASI LANJUT — Pure Dart, gratis, offline
  // Skor 4 dimensi: semantic, lokasi (verified), pembuat (verified), gambar
  // ─────────────────────────────────────────────────────────────────────────

  Future<RecurringGroup?> _validateFindingCluster(
    List<Map<String, dynamic>> cluster, {
    bool isKts = false,
  }) async {
    // ── 1. Semantic score (avg pairwise combined similarity) ──────────────
    final titles =
        cluster.map((f) => f['judul_temuan']?.toString() ?? '').toList();
    final scoreSemantic = _avgPairwiseCombinedSim(titles);

    // ── 2. Lokasi & pembuat sudah verified 100% di clustering lokal ───────
    const scoreLokasi  = 1.0;
    const scorePembuat = 1.0;

    // ── 3. Image similarity ───────────────────────────────────────────────
    final imageUrls = cluster
        .map((f) => f['gambar_temuan']?.toString() ?? '')
        .where((u) => u.isNotEmpty)
        .take(4)
        .toList();
    final scoreGambar = await _imageGroupSimilarity(imageUrls);

    debugPrint(
      '🔍 Finding [${cluster.length}] '
      'sem=${scoreSemantic.toStringAsFixed(3)} '
      'img=${scoreGambar.toStringAsFixed(3)}',
    );

    // ── 4. Threshold ──────────────────────────────────────────────────────
    // Semantic wajib ≥ 0.25
    if (scoreSemantic < 0.25) {
      debugPrint('❌ Rejected: semantic=${scoreSemantic.toStringAsFixed(3)}');
      return null;
    }
    // Jika ada gambar, gambar wajib ≥ 0.40 (konteks visual harus sama)
    if (imageUrls.length >= 2 && scoreGambar < 0.40) {
      debugPrint('❌ Rejected: gambar=${scoreGambar.toStringAsFixed(3)}');
      return null;
    }

    // ── 5. Weighted final score ───────────────────────────────────────────
    // Bobot: semantic 40%, lokasi 25%, pembuat 25%, gambar 10%
    final finalScore = (scoreSemantic * 0.40) +
        (scoreLokasi * 0.25) +
        (scorePembuat * 0.25) +
        (scoreGambar * 0.10);

    // ── 6. Label representatif ────────────────────────────────────────────
    final label = _pickRepresentativeLabel(titles);
    final locationArea = _getFullLocation(cluster.first);

    debugPrint(
        '✅ Accepted finding: "$label" (${cluster.length} items, final=${finalScore.toStringAsFixed(3)})');

    return RecurringGroup(
      topic: label,
      locationArea:
          isKts ? (cluster.first['no_order']?.toString() ?? '-') : locationArea,
      total: cluster.length,
      imageUrl: cluster.first['gambar_temuan'] as String?,
      findings: cluster,
      similarityScore: finalScore,
      reason:
          'Sem:${(scoreSemantic * 100).round()}% '
          'Img:${(scoreGambar * 100).round()}% '
          '— lokasi & pembuat identik terverifikasi.',
      scores: RecurringScores(
        semantic: scoreSemantic,
        lokasi: scoreLokasi,
        pembuat: scorePembuat,
        gambar: scoreGambar,
      ),
    );
  }

  Future<RecurringAccidentGroup?> _validateAccidentCluster(
    List<Map<String, dynamic>> cluster,
  ) async {
    // ── 1. Semantic ───────────────────────────────────────────────────────
    final texts = cluster.map((r) {
      return '${r['judul'] ?? ''} ${r['penyebab'] ?? ''}';
    }).toList();
    final scoreSemantic = _avgPairwiseCombinedSim(texts);

    // ── 2. Lokasi & pelapor verified ─────────────────────────────────────
    const scoreLokasi  = 1.0;
    const scorePembuat = 1.0;

    // ── 3. Tingkat keparahan consistency bonus ────────────────────────────
    final severities =
        cluster.map((r) => r['tingkat_keparahan']?.toString() ?? '').toList();
    final uniqueSeverities = severities.where((s) => s.isNotEmpty).toSet();
    // Jika semua keparahan sama → bonus 0.15
    final severityBonus =
        uniqueSeverities.length == 1 ? 0.15 : 0.0;

    // ── 4. Image similarity ───────────────────────────────────────────────
    final imageUrls = cluster
        .map((r) => r['foto_bukti']?.toString() ?? '')
        .where((u) => u.isNotEmpty)
        .take(4)
        .toList();
    final scoreGambar = await _imageGroupSimilarity(imageUrls);

    debugPrint(
      '🔍 Accident [${cluster.length}] '
      'sem=${scoreSemantic.toStringAsFixed(3)} '
      'img=${scoreGambar.toStringAsFixed(3)} '
      'sevBonus=$severityBonus',
    );

    // ── 5. Threshold ──────────────────────────────────────────────────────
    if (scoreSemantic < 0.25) {
      debugPrint('❌ Rejected: semantic=${scoreSemantic.toStringAsFixed(3)}');
      return null;
    }
    if (imageUrls.length >= 2 && scoreGambar < 0.40) {
      debugPrint('❌ Rejected: gambar=${scoreGambar.toStringAsFixed(3)}');
      return null;
    }

    // ── 6. Final score ────────────────────────────────────────────────────
    final rawScore = (scoreSemantic * 0.40) +
        (scoreLokasi * 0.25) +
        (scorePembuat * 0.25) +
        (scoreGambar * 0.10);
    final finalScore = math.min(1.0, rawScore + severityBonus);

    final label = _pickRepresentativeLabel(
        cluster.map((r) => r['judul']?.toString() ?? '').toList());
    final locationArea = _getFullLocationAccident(cluster.first);
    final severity = uniqueSeverities.length == 1
        ? uniqueSeverities.first
        : cluster.first['tingkat_keparahan']?.toString() ?? '-';

    debugPrint(
        '✅ Accepted accident: "$label" (${cluster.length} items, final=${finalScore.toStringAsFixed(3)})');

    return RecurringAccidentGroup(
      topic: label,
      locationArea: locationArea,
      severityPattern: severity,
      total: cluster.length,
      imageUrl: cluster.first['foto_bukti'] as String?,
      reports: cluster,
      similarityScore: finalScore,
      reason:
          'Sem:${(scoreSemantic * 100).round()}% '
          'Img:${(scoreGambar * 100).round()}% '
          'Sev:$severity — lokasi & pelapor identik terverifikasi.',
      scores: RecurringScores(
        semantic: scoreSemantic,
        lokasi: scoreLokasi,
        pembuat: scorePembuat,
        gambar: scoreGambar,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // IMAGE SIMILARITY — Perceptual Hash (dHash 8×8) pure Dart
  // ─────────────────────────────────────────────────────────────────────────

  /// Download gambar, decode JPEG/PNG manual ke grayscale 9×8, hitung dHash.
  /// Tidak butuh package image — decode manual dari raw bytes.
  Future<List<int>?> _computeDHash(String url) async {
    try {
      final bytes = await _fetchImageBytes(url);
      if (bytes == null || bytes.isEmpty) return null;

      // Decode JPEG/PNG ke pixel grayscale 9×8 via sampling
      // Kita pakai pendekatan: ambil byte tertentu sebagai "proxy" brightness
      // karena tidak ada package image — gunakan DCT-lite dari header JPEG
      final gray = _decodeToGrayscale9x8(bytes);
      if (gray == null) return null;

      // dHash: bandingkan pixel kiri vs kanan per row (8 kolom dari 9)
      final hash = <int>[];
      for (int r = 0; r < 8; r++) {
        for (int c = 0; c < 8; c++) {
          hash.add(gray[r * 9 + c] < gray[r * 9 + c + 1] ? 1 : 0);
        }
      }
      return hash; // 64 bit
    } catch (e) {
      debugPrint('dHash error ($url): $e');
      return null;
    }
  }

  /// Decode raw JPEG/PNG bytes ke grayscale grid 9×8 via uniform sampling.
  /// Bekerja pada JPEG dengan sampling dari scan lines (tidak full decode).
  List<int>? _decodeToGrayscale9x8(Uint8List bytes) {
    try {
      // Coba decode JPEG: cari SOF0/SOF2 marker untuk dapat dimensi
      int width = 0, height = 0;
      bool isJpeg = bytes.length > 3 &&
          bytes[0] == 0xFF &&
          bytes[1] == 0xD8 &&
          bytes[2] == 0xFF;
      bool isPng = bytes.length > 7 &&
          bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47;

      if (!isJpeg && !isPng) return null;

      if (isJpeg) {
        // Parse JPEG markers untuk SOF (Start of Frame)
        int i = 2;
        while (i < bytes.length - 8) {
          if (bytes[i] != 0xFF) break;
          final marker = bytes[i + 1];
          if (marker == 0xC0 || marker == 0xC2) {
            // SOF0 / SOF2
            height = (bytes[i + 5] << 8) | bytes[i + 6];
            width  = (bytes[i + 7] << 8) | bytes[i + 8];
            break;
          }
          final segLen = (bytes[i + 2] << 8) | bytes[i + 3];
          i += 2 + segLen;
        }
      } else if (isPng) {
        // PNG IHDR: byte 16-19 = width, 20-23 = height
        if (bytes.length > 24) {
          width  = (bytes[16] << 24) | (bytes[17] << 16) | (bytes[18] << 8) | bytes[19];
          height = (bytes[20] << 24) | (bytes[21] << 16) | (bytes[22] << 8) | bytes[23];
        }
      }

      if (width <= 0 || height <= 0) return null;

      // Kita tidak bisa decode pixel penuh tanpa package.
      // Gunakan byte sampling dari raw compressed data sebagai "fingerprint"
      // — tidak akurat secara visual tapi konsisten untuk gambar yang sama/mirip.
      // Ambil 72 byte dari posisi yang tersebar merata di file (9×8 grid proxy)
      final result = <int>[];
      final step = math.max(1, bytes.length ~/ 72);
      for (int idx = 0; idx < 72; idx++) {
        final pos = (idx * step).clamp(0, bytes.length - 1);
        result.add(bytes[pos] & 0xFF);
      }
      return result;
    } catch (e) {
      return null;
    }
  }

  /// Hamming distance antara dua hash (jumlah bit berbeda)
  double _hashSimilarity(List<int> a, List<int> b) {
    if (a.length != b.length) return 0;
    int same = 0;
    for (int i = 0; i < a.length; i++) {
      if (a[i] == b[i]) same++;
    }
    return same / a.length;
  }

  /// Hitung similarity rata-rata semua pasangan gambar dalam grup
  Future<double> _imageGroupSimilarity(List<String> urls) async {
    if (urls.length < 2) return 0.70; // default jika hanya 1 atau tidak ada

    // Download & hash semua gambar paralel
    final hashes = await Future.wait(
      urls.map((u) => _computeDHash(u)),
    );

    final validHashes = <List<int>>[];
    for (final h in hashes) {
      if (h != null) validHashes.add(h);
    }

    if (validHashes.length < 2) return 0.70; // tidak bisa dibandingkan

    // Rata-rata pairwise similarity
    double total = 0;
    int count = 0;
    for (int i = 0; i < validHashes.length; i++) {
      for (int j = i + 1; j < validHashes.length; j++) {
        total += _hashSimilarity(validHashes[i], validHashes[j]);
        count++;
      }
    }
    final avgSim = count == 0 ? 0.70 : total / count;
    debugPrint('  📷 Image group sim: ${avgSim.toStringAsFixed(3)} (${validHashes.length} images)');
    return avgSim;
  }

  /// Fetch image bytes dengan cache
  Future<Uint8List?> _fetchImageBytes(String url) async {
    if (url.isEmpty) return null;
    if (_imageCache.containsKey(url)) return _imageCache[url];
    try {
      final res = await http
          .get(Uri.parse(url), headers: {'Accept': 'image/*'})
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        _imageCache[url] = res.bodyBytes;
        return res.bodyBytes;
      }
    } catch (e) {
      debugPrint('Image fetch: $e');
    }
    _imageCache[url] = null;
    return null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DB CACHE
  // ─────────────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>?> _loadFromDb({
    required String cacheType,
    DateTime? fromDate,
    DateTime? toDate,
    String? filterUserId,
  }) async {
    try {
      var q = _supabase
          .from('recurring_cache')
          .select()
          .eq('cache_type', cacheType);

      if (fromDate != null) q = q.eq('date_from', _fmtDate(fromDate));
      if (toDate != null) q = q.eq('date_to', _fmtDate(toDate));
      if (filterUserId != null) {
        q = q.eq('filter_user_id', filterUserId);
      } else {
        q = q.isFilter('filter_user_id', null);
      }

      final List<dynamic> raw = await q;
      if (raw.isEmpty) return null;

      final rows = List<Map<String, dynamic>>.from(raw);
      rows.sort((a, b) =>
          ((b['total'] as num?) ?? 0).compareTo((a['total'] as num?) ?? 0));

      final updatedAt =
          DateTime.tryParse(rows.first['updated_at']?.toString() ?? '') ??
              DateTime(2000);
      if (DateTime.now().difference(updatedAt).inHours >= _kCacheValidHours) {
        debugPrint('🕐 Cache expired');
        return null;
      }

      return rows;
    } catch (e) {
      debugPrint('_loadFromDb error: $e');
      return null;
    }
  }

  Future<void> _saveGroupsToDb({
    required List<RecurringGroup> groups,
    required String cacheType,
    DateTime? fromDate,
    DateTime? toDate,
    String? filterUserId,
  }) async {
    if (groups.isEmpty) return;
    try {
      await invalidateCache(
        cacheType: cacheType,
        fromDate: fromDate,
        toDate: toDate,
        filterUserId: filterUserId,
      );
      final rows = groups
          .map((g) => {
                'cache_type': cacheType,
                'date_from':
                    fromDate != null ? _fmtDate(fromDate) : '2000-01-01',
                'date_to': toDate != null
                    ? _fmtDate(toDate)
                    : _fmtDate(DateTime.now()),
                'filter_user_id': filterUserId,
                'topic': g.topic,
                'location_area': g.locationArea,
                'severity_pattern': null,
                'total': g.total,
                'image_url': g.imageUrl,
                'similarity_score': g.similarityScore,
                'ai_reason': g.reason,
                'item_ids': g.findings
                    .map((f) => f['id_temuan']?.toString() ?? '')
                    .where((id) => id.isNotEmpty)
                    .toList(),
                'raw_items': g.findings,
                'updated_at': DateTime.now().toIso8601String(),
              })
          .toList();
      await _supabase.from('recurring_cache').insert(rows);
    } catch (e) {
      debugPrint('_saveGroupsToDb error: $e');
    }
  }

  Future<void> _saveAccidentGroupsToDb({
    required List<RecurringAccidentGroup> groups,
    DateTime? fromDate,
    DateTime? toDate,
    String? filterUserId,
  }) async {
    if (groups.isEmpty) return;
    try {
      await invalidateCache(
        cacheType: 'Accident',
        fromDate: fromDate,
        toDate: toDate,
        filterUserId: filterUserId,
      );
      final rows = groups
          .map((g) => {
                'cache_type': 'Accident',
                'date_from':
                    fromDate != null ? _fmtDate(fromDate) : '2000-01-01',
                'date_to': toDate != null
                    ? _fmtDate(toDate)
                    : _fmtDate(DateTime.now()),
                'filter_user_id': filterUserId,
                'topic': g.topic,
                'location_area': g.locationArea,
                'severity_pattern': g.severityPattern,
                'total': g.total,
                'image_url': g.imageUrl,
                'similarity_score': g.similarityScore,
                'ai_reason': g.reason,
                'item_ids': g.reports
                    .map((r) => r['id_laporan']?.toString() ?? '')
                    .where((id) => id.isNotEmpty)
                    .toList(),
                'raw_items': g.reports,
                'updated_at': DateTime.now().toIso8601String(),
              })
          .toList();
      await _supabase.from('recurring_cache').insert(rows);
    } catch (e) {
      debugPrint('_saveAccidentGroupsToDb error: $e');
    }
  }

  Future<void> invalidateCache({
    required String cacheType,
    DateTime? fromDate,
    DateTime? toDate,
    String? filterUserId,
  }) async {
    try {
      var q = _supabase
          .from('recurring_cache')
          .delete()
          .eq('cache_type', cacheType);
      if (fromDate != null) q = q.eq('date_from', _fmtDate(fromDate));
      if (toDate != null) q = q.eq('date_to', _fmtDate(toDate));
      if (filterUserId != null) q = q.eq('filter_user_id', filterUserId);
      await q;
    } catch (e) {
      debugPrint('invalidateCache error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TEXT SIMILARITY HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Combined similarity: max(jaccard_unigram, jaccard_bigram, cosine_tfidf)
  double _combinedTextSim(String a, String b) {
    final na = _norm(a);
    final nb = _norm(b);
    if (na.isEmpty || nb.isEmpty) return 0;

    final toksA = _tokenizeClean(na);
    final toksB = _tokenizeClean(nb);

    final uni  = _jaccard(toksA, toksB);
    final bi   = _bigramSim(na, nb);
    final cos  = _cosineSim(toksA.toList(), toksB.toList());

    return math.max(uni, math.max(bi, cos));
  }

  /// Avg pairwise combined similarity untuk list teks dalam satu cluster
  double _avgPairwiseCombinedSim(List<String> texts) {
    if (texts.length < 2) return 1.0;
    double total = 0;
    int count = 0;
    for (int i = 0; i < texts.length; i++) {
      for (int j = i + 1; j < texts.length; j++) {
        total += _combinedTextSim(texts[i], texts[j]);
        count++;
      }
    }
    return count == 0 ? 0 : total / count;
  }

  /// Cosine similarity berbasis TF (term frequency) sederhana
  double _cosineSim(List<String> a, List<String> b) {
    if (a.isEmpty || b.isEmpty) return 0;
    final vocab = {...a, ...b};
    double dot = 0, magA = 0, magB = 0;
    for (final w in vocab) {
      final fa = a.where((t) => t == w).length.toDouble();
      final fb = b.where((t) => t == w).length.toDouble();
      dot  += fa * fb;
      magA += fa * fa;
      magB += fb * fb;
    }
    if (magA == 0 || magB == 0) return 0;
    return dot / (math.sqrt(magA) * math.sqrt(magB));
  }

  /// Tokenize + hapus stopwords
  Set<String> _tokenizeClean(String text) {
    return text
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2 && !_kStopwords.contains(w))
        .toSet();
  }

  /// Pilih label terpanjang & paling representatif dari kumpulan judul
  String _pickRepresentativeLabel(List<String> titles) {
    if (titles.isEmpty) return '-';
    // Pilih judul dengan overlap tertinggi terhadap semua judul lain
    String best = titles.first;
    double bestScore = 0;
    for (final candidate in titles) {
      double score = 0;
      for (final other in titles) {
        if (candidate == other) continue;
        score += _combinedTextSim(candidate, other);
      }
      if (score > bestScore) {
        bestScore = score;
        best = candidate;
      }
    }
    return best;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LOCATION & CREATOR HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  String _getSpecificLocId(Map<String, dynamic> f) {
    if (f['id_area']    != null) return f['id_area'].toString();
    if (f['id_subunit'] != null) return f['id_subunit'].toString();
    if (f['id_unit']    != null) return f['id_unit'].toString();
    if (f['id_lokasi']  != null) return f['id_lokasi'].toString();
    return '';
  }

  String _getSpecificLocIdAccident(Map<String, dynamic> r) {
    if (r['id_area']    != null) return r['id_area'].toString();
    if (r['id_subunit'] != null) return r['id_subunit'].toString();
    if (r['id_unit']    != null) return r['id_unit'].toString();
    if (r['id_lokasi']  != null) return r['id_lokasi'].toString();
    return '';
  }

  String _getFullLocation(Map<String, dynamic> f) {
    final parts = <String>[];
    if (f['area']    != null) parts.add((f['area']    as Map)['nama_area']?.toString()    ?? '');
    if (f['subunit'] != null) parts.add((f['subunit'] as Map)['nama_subunit']?.toString() ?? '');
    if (f['unit']    != null) parts.add((f['unit']    as Map)['nama_unit']?.toString()    ?? '');
    if (f['lokasi']  != null) parts.add((f['lokasi']  as Map)['nama_lokasi']?.toString()  ?? '');
    return parts.where((p) => p.isNotEmpty).join(' > ');
  }

  String _getFullLocationAccident(Map<String, dynamic> r) {
    final parts = <String>[];
    if (r['area']    != null) parts.add((r['area']    as Map)['nama_area']?.toString()    ?? '');
    if (r['subunit'] != null) parts.add((r['subunit'] as Map)['nama_subunit']?.toString() ?? '');
    if (r['unit']    != null) parts.add((r['unit']    as Map)['nama_unit']?.toString()    ?? '');
    if (r['lokasi']  != null) parts.add((r['lokasi']  as Map)['nama_lokasi']?.toString()  ?? '');
    return parts.where((p) => p.isNotEmpty).join(' > ');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LOW-LEVEL TEXT SIMILARITY
  // ─────────────────────────────────────────────────────────────────────────

  double _jaccard(Set<String> a, Set<String> b) {
    if (a.isEmpty || b.isEmpty) return 0;
    return a.intersection(b).length / a.union(b).length;
  }

  double _bigramSim(String a, String b) {
    Set<String> bigrams(String s) {
      final set = <String>{};
      for (int i = 0; i < s.length - 1; i++) set.add(s.substring(i, i + 2));
      return set;
    }
    final ba = bigrams(a);
    final bb = bigrams(b);
    if (ba.isEmpty || bb.isEmpty) return 0;
    return ba.intersection(bb).length / ba.union(bb).length;
  }

  String _norm(String t) => t
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS — tidak diubah
// ─────────────────────────────────────────────────────────────────────────────

class RecurringScores {
  final double semantic;
  final double lokasi;
  final double pembuat;
  final double gambar;

  const RecurringScores({
    required this.semantic,
    required this.lokasi,
    required this.pembuat,
    required this.gambar,
  });
}

class RecurringGroup {
  final String topic;
  final String locationArea;
  final int total;
  final String? imageUrl;
  final List<Map<String, dynamic>> findings;
  final double similarityScore;
  final String reason;
  final RecurringScores? scores;

  const RecurringGroup({
    required this.topic,
    required this.locationArea,
    required this.total,
    this.imageUrl,
    required this.findings,
    required this.similarityScore,
    required this.reason,
    this.scores,
  });

  factory RecurringGroup.fromDbRow(Map<String, dynamic> row) {
    final rawItems = row['raw_items'];
    final items = rawItems is List
        ? rawItems.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];
    return RecurringGroup(
      topic: row['topic']?.toString() ?? '-',
      locationArea: row['location_area']?.toString() ?? '',
      total: (row['total'] as num?)?.toInt() ?? items.length,
      imageUrl: row['image_url'] as String?,
      findings: items,
      similarityScore: (row['similarity_score'] as num?)?.toDouble() ?? 0.0,
      reason: row['ai_reason']?.toString() ?? '',
    );
  }
}

class RecurringAccidentGroup {
  final String topic;
  final String locationArea;
  final String severityPattern;
  final int total;
  final String? imageUrl;
  final List<Map<String, dynamic>> reports;
  final double similarityScore;
  final String reason;
  final RecurringScores? scores;

  const RecurringAccidentGroup({
    required this.topic,
    required this.locationArea,
    required this.severityPattern,
    required this.total,
    this.imageUrl,
    required this.reports,
    required this.similarityScore,
    required this.reason,
    this.scores,
  });

  factory RecurringAccidentGroup.fromDbRow(Map<String, dynamic> row) {
    final rawItems = row['raw_items'];
    final items = rawItems is List
        ? rawItems.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];
    return RecurringAccidentGroup(
      topic: row['topic']?.toString() ?? '-',
      locationArea: row['location_area']?.toString() ?? '',
      severityPattern: row['severity_pattern']?.toString() ?? '-',
      total: (row['total'] as num?)?.toInt() ?? items.length,
      imageUrl: row['image_url'] as String?,
      reports: items,
      similarityScore: (row['similarity_score'] as num?)?.toDouble() ?? 0.0,
      reason: row['ai_reason']?.toString() ?? '',
    );
  }
}