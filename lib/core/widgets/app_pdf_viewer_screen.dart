import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../injection.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/compact_app_bar.dart';

class AppPdfViewerScreen extends StatefulWidget {
  final String title;
  final String pdfUrl;
  final String folderName;
  final String docId;

  const AppPdfViewerScreen({
    super.key,
    required this.title,
    required this.pdfUrl,
    required this.folderName,
    required this.docId,
  });

  @override
  State<AppPdfViewerScreen> createState() => _AppPdfViewerScreenState();
}

class _AppPdfViewerScreenState extends State<AppPdfViewerScreen> {
  bool _isLoading = true;
  Uint8List? _pdfBytes;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (kIsWeb && !widget.pdfUrl.startsWith('mock://') && widget.pdfUrl.isNotEmpty) {
      _launchInNewTab();
    } else {
      _loadPdf();
    }
  }

  Future<void> _launchInNewTab() async {
    final uri = Uri.parse(widget.pdfUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not launch PDF URL in new tab: $e');
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _loadPdf() async {
    if (widget.pdfUrl.startsWith('mock://')) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      try {
        final storage = locator<StorageService>();
        final bytes = await storage.downloadPdf(
          folderName: widget.folderName,
          docId: widget.docId,
          url: widget.pdfUrl,
        );
        if (bytes != null) {
          setState(() {
            _pdfBytes = bytes;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = 'Failed to load PDF content from mock storage.';
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _error = 'Error: $e';
          _isLoading = false;
        });
      }
    } else {
      // Direct network load
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandBackground,
      appBar: CompactAppBar(
        title: widget.title,
        subtitle: 'Document viewer',
        rightIcon: Icons.picture_as_pdf_outlined,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.brandPrimary),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                        const SizedBox(height: 16),
                        const Text(
                          'Failed to Load PDF',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              : _pdfBytes != null
                  ? SfPdfViewer.memory(_pdfBytes!)
                  : SfPdfViewer.network(widget.pdfUrl),
    );
  }
}
