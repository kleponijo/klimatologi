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
  final _pumpStartController = TextEditingController();
  final _pumpEndController = TextEditingController();
  final _d0Controller = TextEditingController();
  final _dmaxManualController = TextEditingController();

  void _syncControllers(EvaporasiSettingsState s) {
    final rendah = s.thresholdRendah.toStringAsFixed(1);
    final tinggi = s.thresholdTinggi.toStringAsFixed(1);
    final offset = s.koreksiOffset.toStringAsFixed(2);
    final pumpStart = s.pumpStartTime;
    final pumpEnd = s.pumpEndTime;
    final d0 = s.d0 == 0 ? '' : s.d0.toString();
    final dmaxManual = s.dmaxManual == 0 ? '' : s.dmaxManual.toString();

    if (_rendahController.text != rendah) {
      _rendahController.text = rendah;
    }
    if (_tinggiController.text != tinggi) {
      _tinggiController.text = tinggi;
    }
    if (_offsetController.text != offset) {
      _offsetController.text = offset;
    }
    if (_pumpStartController.text != pumpStart) {
      _pumpStartController.text = pumpStart;
    }
    if (_pumpEndController.text != pumpEnd) {
      _pumpEndController.text = pumpEnd;
    }
    if (_d0Controller.text != d0) {
      _d0Controller.text = d0;
    }
    if (_dmaxManualController.text != dmaxManual) {
      _dmaxManualController.text = dmaxManual;
    }
  }

  Future<void> _pickPumpTime(BuildContext context, TextEditingController controller, ValueChanged<String> onSelected, String initialValue) async {
    final parts = initialValue.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 6,
      minute: int.tryParse(parts[1]) ?? 0,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: 'Pilih Jam Pompa',
    );
    if (picked != null) {
      final value = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      controller.text = value;
      onSelected(value);
    }
  }

  @override
  void dispose() {
    _rendahController.dispose();
    _tinggiController.dispose();
    _offsetController.dispose();
    _pumpStartController.dispose();
    _pumpEndController.dispose();
    _d0Controller.dispose();
    _dmaxManualController.dispose();
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
                        _sectionTitle('Kontrol Pompa'),
                        const SizedBox(height: 6),
                        Text(
                          'Atur jam mulai dan selesai pompa secara langsung dari aplikasi.',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 12),
                        _SettingsCard(children: [
                          _TimePickerField(
                            controller: _pumpStartController,
                            label: 'Jam Mulai Pompa',
                            helper: 'Pilih jam mulai pompa bekerja.',
                            onTap: () => _pickPumpTime(
                              context,
                              _pumpStartController,
                              (value) => bloc.add(EvaporasiPumpStartChanged(value)),
                              state.pumpStartTime,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _TimePickerField(
                            controller: _pumpEndController,
                            label: 'Jam Selesai Pompa',
                            helper: 'Pilih jam berhenti pompa.',
                            onTap: () => _pickPumpTime(
                              context,
                              _pumpEndController,
                              (value) => bloc.add(EvaporasiPumpEndChanged(value)),
                              state.pumpEndTime,
                            ),
                          ),
                        ]),
                        const SizedBox(height: 24),
                        _sectionTitle('Kalibrasi Raw Sensor'),
                        const SizedBox(height: 6),
                        Text(
                          'Masukkan nilai D0 dan DMAX secara manual untuk kalibrasi sensor tanpa upload firmware.',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 12),
                        _SettingsCard(children: [
                          _NumericField(
                            controller: _d0Controller,
                            label: 'Nilai D0',
                            hint: 'Contoh: 120',
                            helper: 'Nilai sensor saat kondisi paling kering.',
                            onChanged: (v) {
                              final d = int.tryParse(v);
                              if (d != null && d >= 0) {
                                bloc.add(EvaporasiD0Changed(d));
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          _NumericField(
                            controller: _dmaxManualController,
                            label: 'Nilai DMAX Manual',
                            hint: 'Contoh: 1023',
                            helper: 'Kalibrasi nilai maksimum sensor secara manual.',
                            onChanged: (v) {
                              final d = int.tryParse(v);
                              if (d != null && d >= 0) {
                                bloc.add(EvaporasiDmaxManualChanged(d));
                              }
                            },
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

class _TimePickerField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String helper;
  final VoidCallback onTap;

  const _TimePickerField({
    required this.controller,
    required this.label,
    required this.helper,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'HH:mm',
        helperText: helper,
        helperMaxLines: 2,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        suffixIcon: const Icon(Icons.schedule_rounded),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        isDense: true,
      ),
      onTap: onTap,
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

class _RealtimeInfo extends StatelessWidget {
  final EvaporasiSettingsState state;
  const _RealtimeInfo({required this.state});

  String _fmtDate(DateTime? d) {
    if (d == null) return '--';
    final l = d.toLocal();
    return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')}/${l.year} ${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}:${l.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.devices_rounded, size: 15, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Text('Informasi Perangkat', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 12, runSpacing: 8, children: [
          _InfoTile(label: 'Firmware', value: state.firmwareVersion),
          _InfoTile(label: 'WiFi', value: state.wifiConnected ? 'Terhubung' : 'Tidak'),
          _InfoTile(label: 'Firebase', value: state.firebaseConnected ? 'Terhubung' : 'Tidak'),
          _InfoTile(label: 'D0 aktif', value: state.activeD0 == 0 ? '--' : state.activeD0.toString()),
          _InfoTile(label: 'DMAX aktif', value: state.activeDmax == 0 ? '--' : state.activeDmax.toString()),
          _InfoTile(label: 'Terakhir', value: _fmtDate(state.lastUpdate)),
        ])
      ]),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}
