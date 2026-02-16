import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ListCard extends StatelessWidget {
  const ListCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(12),
    this.borderColor,
    this.boxShadow,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor ?? const Color(0xFFE6E9F2)),
          boxShadow: boxShadow,
        ),
        child: child,
      ),
    );
  }
}

class ValueRow extends StatelessWidget {
  const ValueRow({
    super.key,
    required this.items,
  });

  final List<ValueItem> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          Expanded(child: _ValueBlock(item: items[i])),
          if (i != items.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class ValueItem {
  const ValueItem({
    required this.label,
    required this.value,
    this.emphasis = false,
  });

  final String label;
  final String value;
  final bool emphasis;
}

class _ValueBlock extends StatelessWidget {
  const _ValueBlock({required this.item});

  final ValueItem item;

  @override
  Widget build(BuildContext context) {
    final valueColor =
        item.emphasis ? const Color(0xFF2C7BFE) : const Color(0xFF111827);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.label,
          style: GoogleFonts.poppins(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF8B93A4),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          item.value,
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class SummaryStat extends StatelessWidget {
  const SummaryStat({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.alignCenter = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool alignCenter;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignCenter ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Container(
          height: 28,
          width: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFE7F2FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF2C7BFE)),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          textAlign: alignCenter ? TextAlign.center : TextAlign.start,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: alignCenter ? TextAlign.center : TextAlign.start,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF8B93A4),
          ),
        ),
      ],
    );
  }
}
