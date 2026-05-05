import 'package:flutter/material.dart';

class ExportExcelButton extends StatefulWidget {
  final Future<void> Function() onExport;
  final String label;

  const ExportExcelButton({
    super.key,
    required this.onExport,
    this.label = 'Export Excel',
  });

  @override
  State<ExportExcelButton> createState() => _ExportExcelButtonState();
}

class _ExportExcelButtonState extends State<ExportExcelButton> {
  bool _isLoading = false;

  Future<void> _handleExport() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      await widget.onExport();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export Excel berhasil'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal export Excel: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _handleExport,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade700,
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
            : const Icon(Icons.table_view, color: Colors.white),
        label: Text(
          _isLoading ? 'Menyiapkan Excel...' : widget.label,
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
