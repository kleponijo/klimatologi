import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:monitoring_repository/monitoring_repository.dart';

class EvaporasiDateSearchBar extends StatefulWidget {
  final String initialQuery;
  final ValueChanged<String> onQueryChanged;

  const EvaporasiDateSearchBar({
    super.key,
    required this.initialQuery,
    required this.onQueryChanged,
  });


  @override
  State<EvaporasiDateSearchBar> createState() => _EvaporasiDateSearchBarState();
}

class _EvaporasiDateSearchBarState extends State<EvaporasiDateSearchBar> {
  late final TextEditingController _controller;
  DateTime? _selected;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _matches(Evaporasi item, String query) {
    if (query.trim().isEmpty) return true;

    final date = item.timestamp;
    final ddMMyyyy = DateFormat('dd/MM/yyyy', 'id_ID').format(date);
    final ddMMMYYYY = DateFormat('dd MMM yyyy', 'id_ID').format(date);

    final q = query.trim().toLowerCase();
    return ddMMyyyy.toLowerCase().contains(q) || ddMMMYYYY.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(

      controller: _controller,
      decoration: InputDecoration(
        hintText: 'Cari tanggal (dd/MM/yyyy)',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => setState(() => _controller.clear()),
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
      ),
      onChanged: (v) {
        widget.onQueryChanged(v);
        setState(() {});
      },
    );
  }
}

