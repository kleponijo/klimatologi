import 'package:flutter/material.dart';

/// ============================================================
/// Export PDF Button — Reusable Widget
/// Letakkan di: lib/screens/monitoring/shared/widgets/export_pdf_button.dart
/// ============================================================
///
/// Cara pakai (contoh di WindSpeedScreen):
///
///   ExportPdfButton(
///     onExport: () async {
///       await PdfExportService.exportWindSpeedPdf(
///         currentSpeed: state.currentSpeed,
///         period: state.selectedPeriod,
///         speeds: data,
///         timestamp: DateTime.now(),
///       );
///     },
///   )

class ExportPdfButton extends StatefulWidget {
  /// Callback async yang memanggil PdfExportService
  final Future<void> Function() onExport;

  /// Label tombol (default: "Export PDF")
  final String label;

  /// Style: FAB (floating) atau ElevatedButton (inline)
  final ExportButtonStyle style;

  const ExportPdfButton({
    super.key,
    required this.onExport,
    this.label = 'Export PDF',
    this.style = ExportButtonStyle.elevated,
  });

  @override
  State<ExportPdfButton> createState() => _ExportPdfButtonState();
}

class _ExportPdfButtonState extends State<ExportPdfButton> {
  bool _isLoading = false;

  Future<void> _handleExport() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      await widget.onExport();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal export PDF: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.style == ExportButtonStyle.fab
        ? _buildFab()
        : _buildElevated();
  }

  // — FAB style (floating action button)
  Widget _buildFab() {
    return FloatingActionButton.extended(
      onPressed: _isLoading ? null : _handleExport,
      backgroundColor: Colors.blue.shade700,
      icon: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.picture_as_pdf, color: Colors.white),
      label: Text(
        _isLoading ? 'Menyiapkan...' : widget.label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  // — Elevated button style (inline di dalam konten)
  Widget _buildElevated() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _handleExport,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: _isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.picture_as_pdf, color: Colors.white),
        label: Text(
          _isLoading ? 'Menyiapkan PDF...' : widget.label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

enum ExportButtonStyle { fab, elevated }
