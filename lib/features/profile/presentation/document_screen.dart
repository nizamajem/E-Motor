import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/navigation/app_route.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/session/session_manager.dart';
import '../../../components/loading_dialog.dart';
import '../../../components/app_motion.dart';
import '../data/kyc_service.dart';
class DocumentScreen extends StatelessWidget {
  const DocumentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final verificationStatus =
        SessionManager.instance.customerVerificationStatus;
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
                      AppLocalizations.of(context).documents,
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _DocumentTile(
                    title: AppLocalizations.of(context).documentKtp,
                    icon: Icons.credit_card_rounded,
                    docTitle: AppLocalizations.of(context).documentKtp,
                    verificationStatus: verificationStatus,
                  ),
                  const SizedBox(height: 12),
                  _DocumentTile(
                    title: AppLocalizations.of(context).documentSim,
                    icon: Icons.badge_rounded,
                    docTitle: AppLocalizations.of(context).documentSim,
                    verificationStatus: verificationStatus,
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

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.title,
    required this.icon,
    required this.docTitle,
    required this.verificationStatus,
  });

  final String title;
  final IconData icon;
  final String docTitle;
  final String verificationStatus;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (verificationStatus == 'verified') {
          Navigator.of(context).push(
            appRoute(
              DocumentStatusScreen(
                title: docTitle,
                status: DocumentStatus.verified,
              ),
              direction: AxisDirection.left,
            ),
          );
          return;
        }
        if (verificationStatus == 'under_review') {
          Navigator.of(context).push(
            appRoute(
              DocumentStatusScreen(
                title: docTitle,
                status: DocumentStatus.underReview,
              ),
              direction: AxisDirection.left,
            ),
          );
          return;
        }
        Navigator.of(context).push(
          appRoute(
            DocumentUploadScreen(title: docTitle),
            direction: AxisDirection.left,
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE6E9F2)),
        ),
        child: Row(
          children: [
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFE7F2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 20,
                color: const Color(0xFF2C7BFE),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Color(0xFFB4BAC6),
            ),
          ],
        ),
      ),
    );
  }
}

class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({super.key, required this.title});

  final String title;

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  final KycService _kycService = KycService();
  XFile? _front;
  XFile? _back;
  bool _isUploading = false;

  Future<void> _pickImage({required bool isFront}) async {
    final l10n = AppLocalizations.of(context);
    final source = await _showPickSource(context);
    if (source == null) return;
    final file = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null) return;
    if (!_isAllowedFile(file.path)) {
      if (!mounted) return;
      _showSnack(l10n.uploadFileTypeError);
      return;
    }
    if (!mounted) return;
    setState(() {
      if (isFront) {
        _front = file;
      } else {
        _back = file;
      }
    });
  }

  Future<ImageSource?> _showPickSource(BuildContext context) async {
    return showAppBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) {
        return Material(
          color: Colors.transparent,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6E9F2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.photo_camera_outlined),
                    title: Text(AppLocalizations.of(context).camera),
                    onTap: () =>
                        Navigator.of(sheetContext).pop(ImageSource.camera),
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_library_outlined),
                    title: Text(AppLocalizations.of(context).gallery),
                    onTap: () =>
                        Navigator.of(sheetContext).pop(ImageSource.gallery),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final verificationStatus =
        SessionManager.instance.customerVerificationStatus;
    if (verificationStatus == 'verified') {
      return DocumentStatusScreen(
        title: widget.title,
        status: DocumentStatus.verified,
      );
    }
    if (verificationStatus == 'under_review') {
      return DocumentStatusScreen(
        title: widget.title,
        status: DocumentStatus.underReview,
      );
    }
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
                      widget.title,
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Text(
                    _withDoc(
                      AppLocalizations.of(context).uploadHint,
                      _shortName(widget.title),
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF8B93A4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _withDoc(
                      AppLocalizations.of(context).docFrontLabel,
                      _shortName(widget.title),
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _UploadBox(
                    label: AppLocalizations.of(context).uploadFront,
                    file: _front,
                    onTap: () => _pickImage(isFront: true),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _withDoc(
                      AppLocalizations.of(context).docBackLabel,
                      _shortName(widget.title),
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _UploadBox(
                    label: AppLocalizations.of(context).uploadBack,
                    file: _back,
                    onTap: () => _pickImage(isFront: false),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                  child: ElevatedButton(
                  onPressed: _isUploading ? null : _handleUpload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C7BFE),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context).upload,
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

  String _shortName(String value) {
    if (value.contains('KTP')) return 'KTP';
    if (value.contains('SIM')) return 'SIM';
    return value;
  }

  String _withDoc(String template, String doc) {
    return template.replaceAll('{doc}', doc);
  }

  bool _isAllowedFile(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png');
  }

  Future<void> _handleUpload() async {
    final l10n = AppLocalizations.of(context);
    if (_front == null || _back == null) {
      _showSnack(l10n.uploadRequired);
      return;
    }
    final doc = _shortName(widget.title).toLowerCase();
    final frontType = doc == 'ktp' ? 'ktp_front' : 'sim_front';
    final backType = doc == 'ktp' ? 'ktp_back' : 'sim_back';
    setState(() => _isUploading = true);
    showLoadingDialog(context, message: l10n.loadingProcessing, showClose: true);
    try {
      await _kycService.uploadDocument(
        type: frontType,
        file: File(_front!.path),
      );
      await _kycService.uploadDocument(
        type: backType,
        file: File(_back!.path),
      );
      if (!mounted) return;
      hideLoadingDialog(context);
      _showSnack(l10n.uploadSuccess);
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      hideLoadingDialog(context);
      _showSnack(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showSnack(String message) {
    showAppSnackBar(context, message, isError: true);
  }
}

class _UploadBox extends StatelessWidget {
  const _UploadBox({
    required this.label,
    required this.onTap,
    this.file,
  });

  final String label;
  final VoidCallback onTap;
  final XFile? file;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: const Color(0xFFE6E6E6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: file == null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.image_outlined,
                      size: 28,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(file!.path),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
      ),
    );
  }
}

enum DocumentStatus { verified, underReview }

class DocumentStatusScreen extends StatelessWidget {
  const DocumentStatusScreen({
    super.key,
    required this.title,
    required this.status,
  });

  final String title;
  final DocumentStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isVerified = status == DocumentStatus.verified;
    final titleText =
        isVerified ? l10n.documentVerifiedTitle : l10n.documentUnderReviewTitle;
    final bodyText =
        isVerified ? l10n.documentVerifiedBody : l10n.documentUnderReviewBody;
    final icon = isVerified ? Icons.verified_rounded : Icons.hourglass_top_rounded;
    final accent =
        isVerified ? const Color(0xFF2C7BFE) : const Color(0xFFF59E0B);

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
                      title,
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
            const SizedBox(height: 30),
            Container(
              height: 72,
              width: 72,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                icon,
                color: accent,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              titleText,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                bodyText,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF7B8190),
                  height: 1.4,
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
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
}
