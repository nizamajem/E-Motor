import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'history_screen.dart';
import '../../auth/presentation/login_screen.dart';
import '../../../core/navigation/app_route.dart';
import '../../../core/session/session_manager.dart';
import '../../../core/localization/app_localizations.dart';
import '../data/feedback_service.dart';
import '../../../core/network/api_client.dart';

class DetailHistoryScreen extends StatelessWidget {
  const DetailHistoryScreen({
    super.key,
    required this.item,
    this.returnToLogin = false,
    this.returnToDashboard = false,
  });

  final HistoryItem item;
  final bool returnToLogin;
  final bool returnToDashboard;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF2C7BFE);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18, color: Colors.black87),
                    onPressed: () => _handleExit(context),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.detailTrip,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _InfoCard(accent: accent, item: item),
              const SizedBox(height: 16),
              _CostCard(item: item),
              const SizedBox(height: 12),
              _FeedbackButton(
                accent: accent,
                onPressed: () => _openFeedbackSheet(context, accent),
              ),
              if (returnToLogin || returnToDashboard) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _handleExit(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      l10n.done,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handleExit(BuildContext context) {
    if (!returnToLogin) {
      Navigator.of(context).pop();
      return;
    }
    SessionManager.instance.clear();
    Navigator.of(context).pushAndRemoveUntil(
      appRoute(const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _openFeedbackSheet(BuildContext context, Color accent) {
    final controller = TextEditingController();
    int rating = 4;
    bool isSending = false;
    final l10n = AppLocalizations.of(context);
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AnimatedPadding(
              duration: const Duration(milliseconds: 150),
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            height: 4,
                            width: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.giveFeedback,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.feedbackHint,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: List.generate(5, (index) {
                            final filled = index < rating;
                            return GestureDetector(
                              onTap: () => setState(() => rating = index + 1),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(
                                  filled
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  size: 28,
                                  color: filled ? accent : Colors.grey.shade400,
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F9FC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5EAF2)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: TextField(
                            controller: controller,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: l10n.feedbackInput,
                              border: InputBorder.none,
                              hintStyle: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed:
                                    isSending ? null : () => Navigator.of(ctx).pop(),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                  side: const BorderSide(color: Color(0xFFE2E7F0)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  l10n.cancel,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isSending
                                    ? null
                                    : () async {
                                        final text = controller.text.trim();
                                        if (text.isEmpty) {
                                          ScaffoldMessenger.of(ctx).showSnackBar(
                                            SnackBar(content: Text(l10n.feedbackInput)),
                                          );
                                          return;
                                        }
                                        if (rating < 1 || rating > 5) {
                                          return;
                                        }
                                        FocusScope.of(ctx).unfocus();
                                        setState(() => isSending = true);
                                        try {
                                          final session = SessionManager.instance;
                                          final profile = session.userProfile;
                                          final userId =
                                              session.user?.userId ?? profile?['id']?.toString();
                                          final tenantId =
                                              profile?['tenantId']?.toString() ??
                                                  profile?['tenant_id']?.toString();
                                          await FeedbackService().createFeedback(
                                            userId: userId,
                                            tenantId: tenantId,
                                            userCyclingHistoryId: item.id,
                                            rating: rating,
                                            feedback: text,
                                          );
                                          if (context.mounted) {
                                            Navigator.of(ctx).pop();
                                          }
                                          if (context.mounted) {
                                            showDialog<void>(
                                              context: context,
                                              builder: (dialogContext) {
                                                final dialogL10n =
                                                    AppLocalizations.of(dialogContext);
                                                return Dialog(
                                                  insetPadding:
                                                      const EdgeInsets.symmetric(horizontal: 22),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(18),
                                                  ),
                                                  child: Padding(
                                                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                                                    child: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Container(
                                                          height: 56,
                                                          width: 56,
                                                          decoration: BoxDecoration(
                                                            shape: BoxShape.circle,
                                                            color: const Color(0xFF2C7BFE),
                                                            boxShadow: const [
                                                              BoxShadow(
                                                                color: Color(0x332C7BFE),
                                                                blurRadius: 14,
                                                                offset: Offset(0, 6),
                                                              ),
                                                            ],
                                                          ),
                                                          child: const Icon(
                                                            Icons.check_rounded,
                                                            color: Colors.white,
                                                            size: 30,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 12),
                                                        Text(
                                                          dialogL10n.feedbackSuccessTitle,
                                                          textAlign: TextAlign.center,
                                                          style: GoogleFonts.poppins(
                                                            fontSize: 15,
                                                            fontWeight: FontWeight.w800,
                                                            color: Colors.black87,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 6),
                                                        Text(
                                                          dialogL10n.feedbackSuccessBody,
                                                          textAlign: TextAlign.center,
                                                          style: GoogleFonts.poppins(
                                                            fontSize: 12.5,
                                                            fontWeight: FontWeight.w500,
                                                            color: Colors.grey.shade600,
                                                            height: 1.4,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 14),
                                                        SizedBox(
                                                          width: double.infinity,
                                                          child: ElevatedButton(
                                                            onPressed: () =>
                                                                Navigator.of(dialogContext).pop(),
                                                            style: ElevatedButton.styleFrom(
                                                              padding: const EdgeInsets.symmetric(
                                                                  vertical: 11),
                                                              backgroundColor: const Color(0xFF2C7BFE),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(12),
                                                              ),
                                                              elevation: 0,
                                                            ),
                                                            child: Text(
                                                              dialogL10n.feedbackSuccessCta,
                                                              style: GoogleFonts.poppins(
                                                                fontSize: 13,
                                                                fontWeight: FontWeight.w700,
                                                                color: Colors.white,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          }
                                        } on ApiException catch (e) {
                                          ScaffoldMessenger.of(ctx).showSnackBar(
                                            SnackBar(content: Text(e.message)),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(ctx).showSnackBar(
                                            SnackBar(content: Text(e.toString())),
                                          );
                                        } finally {
                                          if (context.mounted) {
                                            setState(() => isSending = false);
                                          }
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                  backgroundColor: accent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: isSending
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        l10n.send,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.accent, required this.item});

  final Color accent;
  final HistoryItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Colors.grey.shade600,
    );
    final value = GoogleFonts.poppins(
      fontSize: 12.5,
      fontWeight: FontWeight.w700,
      color: Colors.grey.shade700,
    );
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LineEntry(l10n.distance, item.distanceKm, label, value),
          const SizedBox(height: 8),
          _LineEntry(l10n.rentalDuration, item.rentalDuration, label, value),
          const SizedBox(height: 8),
          _LineEntry(l10n.emissionReduction, item.emission, label, value),
          const SizedBox(height: 12),
          _SectionDivider(accent: accent, title: l10n.start),
          const SizedBox(height: 8),
          _LineEntry(l10n.date, item.date, label, value),
          const SizedBox(height: 6),
          _LineEntry(l10n.startTime, item.startTime, label, value),
          const SizedBox(height: 6),
          _LineEntry(l10n.startPosition, item.startPlace, label, value,
              maxLines: 2),
          const SizedBox(height: 12),
          _SectionDivider(accent: accent, title: l10n.end),
          const SizedBox(height: 8),
          _LineEntry(l10n.date, item.date, label, value),
          const SizedBox(height: 6),
          _LineEntry(l10n.endTime, item.endTime, label, value),
          const SizedBox(height: 6),
          _LineEntry(l10n.endPosition, item.endPlace, label, value,
              maxLines: 2),
        ],
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({required this.accent, required this.title});

  final Color accent;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: accent.withValues(alpha: 0.25),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: accent,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            color: accent.withValues(alpha: 0.25),
          ),
        ),
      ],
    );
  }
}

class _LineEntry extends StatelessWidget {
  const _LineEntry(
    this.label,
    this.value,
    this.labelStyle,
    this.valueStyle, {
    this.maxLines = 1,
  });

  final String label;
  final String value;
  final TextStyle labelStyle;
  final TextStyle valueStyle;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 4,
          child: Text(label, style: labelStyle),
        ),
        Expanded(
          flex: 5,
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: valueStyle,
          ),
        ),
      ],
    );
  }
}

class _CostCard extends StatelessWidget {
  const _CostCard({required this.item});

  final HistoryItem item;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF2C7BFE);
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F3FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CostLine(l10n.rideCost, item.rideCost, accent),
          const SizedBox(height: 4),
          _CostLine(l10n.idleCost, item.idleCost, accent),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.totalCost,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              Text(
                item.totalCost,
                style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CostLine extends StatelessWidget {
  const _CostLine(this.label, this.value, this.accent);

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: accent,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: accent,
          ),
        ),
      ],
    );
  }
}

class _FeedbackButton extends StatelessWidget {
  const _FeedbackButton({required this.onPressed, required this.accent});

  final VoidCallback onPressed;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: const Color(0xFFF2F4F7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_rounded, color: accent, size: 18),
            const SizedBox(width: 6),
            Text(
              l10n.feedback,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
