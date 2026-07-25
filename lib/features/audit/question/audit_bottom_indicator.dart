import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bottom page indicator khusus untuk Audit Question Manager.
/// Tampilannya meniru gaya AdminUserIndicatorScreen, tapi dibuat
/// sebagai widget terpisah agar tidak perlu mengubah file aslinya.
class AuditBottomIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  // true  = nempel di dasar layar (dengan padding safe-area, bg putih penuh)
  // false = versi ringkas untuk ditaruh di dalam card/section
  final bool pinnedAtBottom;

  const AuditBottomIndicator({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    this.pinnedAtBottom = true,
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
    final indicatorCard = _buildIndicatorCard();

    // VERSI EMBEDDED — dipakai di dalam card tema (paginasi pertanyaan).
    if (!pinnedAtBottom) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: indicatorCard,
      );
    }

    // VERSI NEMPEL DI DASAR LAYAR — dipakai untuk paginasi tema.
    // Aman dari gesture bar / navbar bawaan di semua HP Android.
    final double bottomInset = MediaQuery.of(context).padding.bottom;
    final double bottomSpacing = bottomInset > 0 ? bottomInset + 10 : 16;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(15, 8, 15, bottomSpacing),
      child: indicatorCard,
    );
  }

  Widget _buildIndicatorCard() {
    final bool canPrev = currentPage > 1;
    final bool canNext = currentPage < totalPages;
    final pageNumbers = _visiblePageNumbers();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _mainColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: _mainColor.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildArrowButton(
            icon: Icons.arrow_back_ios_new_rounded,
            enabled: canPrev,
            onTap: () {
              if (!canPrev) return;
              onPageChanged(currentPage - 1);
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                for (final p in pageNumbers) ...[
                  Expanded(child: _buildPageNumberButton(p)),
                  if (p != pageNumbers.last) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          _buildArrowButton(
            icon: Icons.arrow_forward_ios_rounded,
            enabled: canNext,
            onTap: () {
              if (!canNext) return;
              onPageChanged(currentPage + 1);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPageNumberButton(int page) {
    final bool isActive = page == currentPage;
    return GestureDetector(
      onTap: () {
        if (page == currentPage) return;
        onPageChanged(page);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? _mainColor : _mainColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: isActive
              ? null
              : Border.all(color: _mainColor.withValues(alpha: 0.25)),
        ),
        child: Text(
          '$page',
          style: GoogleFonts.poppins(
            color: isActive ? Colors.white : _mainColor,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildArrowButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: enabled
              ? _mainColor.withValues(alpha: 0.12)
              : Colors.grey.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 15,
          color: enabled ? _mainColor : Colors.grey.shade400,
        ),
      ),
    );
  }
}