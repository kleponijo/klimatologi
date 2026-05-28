import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'evaporasi_settings_bloc.dart';

class EvaporasiSettingsScreen extends StatefulWidget {
  const EvaporasiSettingsScreen({super.key});

  @override
  State<EvaporasiSettingsScreen> createState() => _EvaporasiSettingsScreenState();
}

class _EvaporasiSettingsScreenState extends State<EvaporasiSettingsScreen> {
  final _rendahController = TextEditingController();
  final _tinggiController = TextEditingController();
  final _offsetController = TextEditingController();

  void _syncControllers(EvaporasiSettingsState s) {
    final rendah = s.thresholdRendah.toStringAsFixed(1);
    final tinggi = s.thresholdTinggi.toStringAsFixed(1);
    final offset = s.koreksiOffset.toStringAsFixed(2);
    if (_rendahController.text != rendah) {
      _rendahController.text = rendah;
    }
    if (_tinggiController.text != tinggi) {
      _tinggiController.text = tinggi;
    }
    if (_offsetController.text != offset) {
      _offsetController.text = offset;
    }
  }

  void _showResetDmaxDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.restart_alt_rounded, color: Colors.orange),
          SizedBox(width: 8),
          Text('Reset DMAX'),
        ]),
        content: const Text(
          'DMAX akan direset ke nilai default.\n\n'
          'ESP32 akan mencari nilai DMAX baru secara otomatis '
          'pada pembacaan berikutnya.\n\n'
          'Lakukan ini hanya jika sensor diganti atau '
          'kalibrasi ulang diperlukan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<EvaporasiSettingsBloc>().add(EvaporasiDmaxResetRequested());
            },
            icon: const Icon(Icons.restart_alt_rounded, size: 16),
            label: const Text('Reset DMAX'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _rendahController.dispose();
    _tinggiController.dispose();
    _offsetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EvaporasiSettingsBloc()..add(EvaporasiSettingsStarted()),
      child: BlocConsumer<EvaporasiSettingsBloc, EvaporasiSettingsState>(
        listener: (context, state) {
          if (state.status == EvaporasiSettingsStatus.loaded ||
              state.status == EvaporasiSettingsStatus.saved) {
            _syncControllers(state);
          }
          if (state.status == EvaporasiSettingsStatus.saved) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Row(children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text('Pengaturan berhasil disimpan ke Firebase.'),
              ]),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ));
          }
          if (state.status == EvaporasiSettingsStatus.error &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Error: ${state.errorMessage}'),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
            ));
          }
        },
        builder: (context, state) {
          final bloc = context.read<EvaporasiSettingsBloc>();
          final isLoading = state.status == EvaporasiSettingsStatus.loading;
          final isSaving = state.status == EvaporasiSettingsStatus.saving;

          return Scaffold(
            backgroundColor: Colors.grey.shade100,
            appBar: AppBar(
              title: const Text(
                'Pengaturan Evaporasi',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.black,
              elevation: 0,
            ),
            body: isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoCard(
                          'Pengaturan disimpan ke Firebase Firestore dan '
                          'langsung berlaku untuk semua perangkat.',
                        ),
                        const SizedBox(height: 24),
                        _sectionTitle('Batas Status Evaporasi'),
                        const SizedBox(height: 6),
                        Text(
                          'Tentukan nilai (mm) untuk klasifikasi status '
                          'Rendah, Normal, dan Tinggi.',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 12),
                        _SettingsCard(children: [
                          _ThresholdPreview(state: state),
                          const Divider(height: 28),
                          _NumericField(
                            controller: _rendahController,
                            label: 'Batas Rendah–Normal (mm)',
                            hint: 'Contoh: 20.0',
                            helper: 'Nilai < batas ini → Status Rendah. Default: 20.0',
                            onChanged: (v) {
                              final d = double.tryParse(v);
                              if (d != null && d >= 0) {
                                bloc.add(EvaporasiThresholdRendahChanged(d));
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          _NumericField(
                            controller: _tinggiController,
                            label: 'Batas Normal–Tinggi (mm)',
                            hint: 'Contoh: 30.0',
                            helper: 'Nilai ≥ batas ini → Status Tinggi. Default: 30.0',
                            onChanged: (v) {
                              final d = double.tryParse(v);
                              if (d != null && d >= 0) {
                                bloc.add(EvaporasiThresholdTinggiChanged(d));
                              }
                            },
                          ),
                        ]),
                        const SizedBox(height: 24),
                        _sectionTitle('Rumus Kalibrasi E'),
                        const SizedBox(height: 6),
                        Text(
                          'Pilih metode penghitungan nilai evaporasi '
                          'terkalibrasi (E) dari data sensor.',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 12),
                        _SettingsCard(children: [
                          _RumusSelector(
                            selected: state.rumusKalibrasi,
                            onChanged: (v) => bloc.add(EvaporasiRumusKalibrasiChanged(v)),
                          ),
                          const Divider(height: 28),
                          _FormulaPreview(state: state),
                          const Divider(height: 28),
                          _NumericField(
                            controller: _offsetController,
                            label: 'Koreksi Offset (mm)',
                            hint: 'Contoh: 0.0 atau -1.5',
                            helper: 'Nilai ditambahkan ke hasil E. Gunakan negatif untuk koreksi ke bawah.',
                            allowNegative: true,
                            onChanged: (v) {
                              final d = double.tryParse(v);
                              if (d != null) {
                                bloc.add(EvaporasiKoreksiOffsetChanged(d));
                              }
                            },
                          ),
                        ]),
                        const SizedBox(height: 24),
                        _sectionTitle('Interval Pengiriman & Pembacaan'),
                        const SizedBox(height: 6),
                        Text(
                          'Atur seberapa sering ESP32 membaca sensor dan mengirim data. '
                          'Interval lebih pendek = data lebih real-time, baterai lebih boros.',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 12),
                        _SettingsCard(children: [
                          _IntervalSelector(
                            label: 'Interval Baca Sensor',
                            helper: 'Seberapa sering sensor dibaca. Min: 5 detik.',
                            options: const {
                              5000: '5 detik',
                              10000: '10 detik (default)',
                              30000: '30 detik',
                              60000: '1 menit',
                            },
                            selected: state.intervalBaca_ms,
                            onChanged: (v) => bloc.add(EvaporasiIntervalBacaChanged(v)),
                          ),
                          const Divider(height: 24),
                          _IntervalSelector(
                            label: 'Interval Kirim Realtime',
                            helper: 'Frekuensi update data real-time ke Firebase.',
                            options: const {
                              60000: '1 menit',
                              300000: '5 menit (default)',
                              600000: '10 menit',
                            },
                            selected: state.intervalRealtime_ms,
                            onChanged: (v) => bloc.add(EvaporasiIntervalRealtimeChanged(v)),
                          ),
                          const Divider(height: 24),
                          _IntervalSelector(
                            label: 'Interval Simpan History',
                            helper: 'Frekuensi pencatatan ke riwayat Firebase.',
                            options: const {
                              300000: '5 menit',
                              600000: '10 menit (default)',
                              1800000: '30 menit',
                              3600000: '1 jam',
                            },
                            selected: state.intervalHistory_ms,
                            onChanged: (v) => bloc.add(EvaporasiIntervalHistoryChanged(v)),
                          ),
                        ]),
                        const SizedBox(height: 24),
                        _sectionTitle('Kalibrasi DMAX'),
                        const SizedBox(height: 6),
                        Text(
                          'DMAX adalah nilai raw sensor saat panci penuh. '
                          'Diperbarui otomatis oleh ESP32. Reset hanya '
                          'jika sensor diganti atau kalibrasi ulang diperlukan.',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 12),
                        _SettingsCard(children: [
                          _DmaxPanel(
                            dmax: state.dmax,
                            isResetting: state.isResettingDmax,
                            onReset: () => _showResetDmaxDialog(context),
                          ),
                        ]),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: isSaving ? null : () => bloc.add(EvaporasiSettingsSaved()),
                            icon: isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.save_rounded),
                            label: Text(isSaving ? 'Menyimpan...' : 'Simpan ke Firebase'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      );
}

class _ThresholdPreview extends StatelessWidget {
  final EvaporasiSettingsState state;
  const _ThresholdPreview({required this.state});

  @override
  Widget build(BuildContext context) {
    final rendah = state.thresholdRendah;
    final tinggi = state.thresholdTinggi;
    final isValid = rendah < tinggi;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Preview Klasifikasi',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
        const SizedBox(height: 10),
        Row(
          children: [
            _StatusChip('Rendah', '< ${rendah.toStringAsFixed(0)} mm', Colors.green),
            const SizedBox(width: 8),
            _StatusChip('Normal', '${rendah.toStringAsFixed(0)}–${tinggi.toStringAsFixed(0)} mm', Colors.orange),
            const SizedBox(width: 8),
            _StatusChip('Tinggi', '≥ ${tinggi.toStringAsFixed(0)} mm', Colors.red),
          ],
        ),
        if (!isValid) ...[
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.warning_rounded, size: 14, color: Colors.red.shade600),
            const SizedBox(width: 6),
            Text('Batas Rendah harus < batas Tinggi',
                style: TextStyle(fontSize: 11, color: Colors.red.shade600)),
          ]),
        ],
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final String range;
  final Color color;
  const _StatusChip(this.label, this.range, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(range, style: TextStyle(fontSize: 9, color: color), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _RumusSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _RumusSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const options = [
      (
        value: 'selisih_max',
        label: 'Selisih Maksimum',
        subtitle: 'E = max(H kemarin) − max(H hari ini)',
        icon: Icons.trending_down_rounded,
      ),
      (
        value: 'rata_harian',
        label: 'Rata-rata Harian',
        subtitle: 'E = rata(H kemarin) − rata(H hari ini)',
        icon: Icons.bar_chart_rounded,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Metode Kalkulasi',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
        const SizedBox(height: 10),
        ...options.map((opt) {
          final isSelected = opt.value == selected;
          return GestureDetector(
            onTap: () => onChanged(opt.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue.shade50 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.blue.shade400 : Colors.grey.shade200,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(opt.icon, color: isSelected ? Colors.blue.shade700 : Colors.grey.shade500, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(opt.label,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.blue.shade800 : Colors.black87)),
                        const SizedBox(height: 2),
                        Text(opt.subtitle,
                            style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: isSelected ? Colors.blue.shade600 : Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle_rounded, color: Colors.blue.shade600, size: 20),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _FormulaPreview extends StatelessWidget {
  final EvaporasiSettingsState state;
  const _FormulaPreview({required this.state});

  @override
  Widget build(BuildContext context) {
    final rumus = state.rumusKalibrasi == 'selisih_max'
        ? 'E = max(H₁) − max(H₂) + offset'
        : 'E = avg(H₁) − avg(H₂) + offset';
    final offsetStr = state.koreksiOffset >= 0
        ? '+${state.koreksiOffset.toStringAsFixed(2)}'
        : state.koreksiOffset.toStringAsFixed(2);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.functions_rounded, size: 15, color: Colors.amber.shade300),
            const SizedBox(width: 8),
            Text('Preview Rumus',
                style: TextStyle(fontSize: 12, color: Colors.amber.shade300, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 10),
          Text(rumus,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade300, fontFamily: 'monospace')),
          const SizedBox(height: 6),
          Text('offset = $offsetStr mm',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.green.shade300,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String text;
  const _InfoCard(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: Colors.blue.shade600),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 12, color: Colors.blue.shade800)),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _NumericField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String helper;
  final bool allowNegative;
  final ValueChanged<String> onChanged;

  const _NumericField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.helper,
    required this.onChanged,
    this.allowNegative = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          allowNegative ? RegExp(r'^-?[0-9]*\.?[0-9]*') : RegExp(r'[0-9.]'),
        ),
      ],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        helperMaxLines: 2,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        isDense: true,
      ),
      onChanged: onChanged,
    );
  }
}

class _IntervalSelector extends StatelessWidget {
  final String label;
  final String helper;
  final Map<int, String> options;
  final int selected;
  final ValueChanged<int> onChanged;

  const _IntervalSelector({
    required this.label,
    required this.helper,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(helper, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.entries.map((e) {
            final isSelected = e.key == selected;
            return GestureDetector(
              onTap: () => onChanged(e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue.shade700 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.blue.shade700 : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  e.value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _DmaxPanel extends StatelessWidget {
  final int dmax;
  final bool isResetting;
  final VoidCallback onReset;

  const _DmaxPanel({
    required this.dmax,
    required this.isResetting,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nilai DMAX Saat Ini',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.memory_rounded, size: 15, color: Colors.amber.shade300),
                const SizedBox(width: 8),
                Text('Raw Sensor Value',
                    style: TextStyle(fontSize: 12, color: Colors.amber.shade300, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 10),
              Text(
                dmax == 0 ? '-- (belum terbaca)' : dmax.toString(),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: dmax == 0 ? Colors.grey.shade500 : Colors.green.shade300,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Diperbarui otomatis oleh ESP32',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.orange.shade100),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'DMAX = nilai ADC saat panci penuh (tinggi air maksimum). '
                  'Semakin besar DMAX, semakin akurat pembacaan tinggi air.',
                  style: TextStyle(fontSize: 11, color: Colors.orange.shade800),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isResetting ? null : onReset,
            icon: isResetting
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange.shade700),
                  )
                : const Icon(Icons.restart_alt_rounded),
            label: Text(isResetting ? 'Mereset...' : 'Reset DMAX ke Default'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange.shade700,
              side: BorderSide(color: Colors.orange.shade300),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}
