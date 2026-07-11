import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../injection.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';

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
    _loadPdf();
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
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.brandSecondary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
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
