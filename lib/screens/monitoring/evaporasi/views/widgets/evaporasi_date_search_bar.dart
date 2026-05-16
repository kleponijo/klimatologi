import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
                onPressed: () {
                  _controller.clear();
                  widget.onQueryChanged('');
                },
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
      ),
      onChanged: (v) {
        widget.onQueryChanged(v);
      },
    );
  }
}
