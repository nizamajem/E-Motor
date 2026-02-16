import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/localization/app_localizations.dart';
class RechargeScreen extends StatefulWidget {
  const RechargeScreen({super.key});

  @override
  State<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends State<RechargeScreen> {
  final List<_RechargeOption> _options = const [
    _RechargeOption(amount: 10000, bonus: 1000),
    _RechargeOption(amount: 15000, bonus: 1500),
    _RechargeOption(amount: 20000, bonus: 2000),
    _RechargeOption(amount: 30000, bonus: 3000),
    _RechargeOption(amount: 50000, bonus: 5000),
    _RechargeOption(amount: 100000, bonus: 10000),
  ];

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final selected = _options[_selectedIndex];
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    color: const Color(0xFF111827),
                  ),
                  Expanded(
                    child: Text(
                      l10n.rechargeTitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  children: [
                    Text(
                      l10n.rechargePrompt,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF9AA0AA),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFF2C7BFE),
                          width: 1.6,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _formatRupiah(selected.amount),
                          style: GoogleFonts.poppins(
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _options.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        mainAxisExtent: 76,
                      ),
                      itemBuilder: (context, index) {
                        final option = _options[index];
                        final isSelected = index == _selectedIndex;
                        return _RechargeOptionCard(
                          option: option,
                          isSelected: isSelected,
                          onTap: () => setState(() => _selectedIndex = index),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C7BFE),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    l10n.continueLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRupiah(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final idx = digits.length - i;
      buffer.write(digits[i]);
      if (idx > 1 && idx % 3 == 1) {
        buffer.write('.');
      }
    }
    return 'Rp ${buffer.toString()},00';
  }
}

class _RechargeOption {
  const _RechargeOption({
    required this.amount,
    required this.bonus,
  });

  final int amount;
  final int bonus;
}

class _RechargeOptionCard extends StatelessWidget {
  const _RechargeOptionCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final _RechargeOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = isSelected ? Colors.white : const Color(0xFFF4F6F9);
    final border =
        isSelected ? const Color(0xFF2C7BFE) : const Color(0xFFE6E9F2);
    final titleColor =
        isSelected ? const Color(0xFF2C7BFE) : const Color(0xFF9AA0AA);
    final bonusBg =
        isSelected ? const Color(0xFF0DA2E6) : const Color(0xFFE6EBF3);
    final bonusColor =
        isSelected ? Colors.white : const Color(0xFF9AA0AA);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatRupiah(option.amount),
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 3),
              decoration: BoxDecoration(
                color: bonusBg,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Center(
                child: Text(
              '${AppLocalizations.of(context).bonus} ${_formatRupiah(option.bonus)}',
                  style: GoogleFonts.poppins(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                    color: bonusColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRupiah(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final idx = digits.length - i;
      buffer.write(digits[i]);
      if (idx > 1 && idx % 3 == 1) {
        buffer.write('.');
      }
    }
    return 'Rp ${buffer.toString()},00';
  }
}
