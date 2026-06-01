import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class EvaporasiControlPanel extends StatefulWidget {
  const EvaporasiControlPanel({super.key});

  @override
  State<EvaporasiControlPanel> createState() => _EvaporasiControlPanelState();
}

class _EvaporasiControlPanelState extends State<EvaporasiControlPanel> {
  bool _selenoid = false;
  bool _isTogglingSelenoid = false;
  bool _isResettingEvaporasi = false;
  bool _isTriggeringOta = false;
  StreamSubscription<DatabaseEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = FirebaseDatabase.instance
        .ref('Monitoring/realtime')
        .onValue
        .listen(_onRealtimeUpdated);
  }

  void _onRealtimeUpdated(DatabaseEvent event) {
    final data = event.snapshot.value;
    if (data is Map) {
      final rawSelenoid = data['selenoid'];
      final selenoid = _toBool(rawSelenoid, _selenoid);
      if (mounted) {
        setState(() {
          _selenoid = selenoid;
        });
      }
    }
  }

  bool _toBool(dynamic raw, bool fallback) {
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    if (raw is String) {
      final lower = raw.toLowerCase();
      return lower == 'true' || lower == '1';
    }
    return fallback;
  }

  Future<void> _toggleSelenoid() async {
    if (_isTogglingSelenoid) return;
    final nextValue = !_selenoid;
    setState(() {
      _isTogglingSelenoid = true;
    });

    try {
      await Future.wait([
        FirebaseDatabase.instance.ref('Monitoring/selenoid').set(nextValue),
        FirebaseDatabase.instance
            .ref('Monitoring/realtime/selenoid')
            .set(nextValue),
      ]);
      if (mounted) {
        setState(() {
          _selenoid = nextValue;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('Perintah selenoid dikirim: ${nextValue ? 'ON' : 'OFF'}'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal mengirim perintah selenoid: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTogglingSelenoid = false;
        });
      }
    }
  }

  Future<void> _resetEvaporasi() async {
    if (_isResettingEvaporasi) return;
    setState(() {
      _isResettingEvaporasi = true;
    });

    try {
      await Future.wait([
        FirebaseDatabase.instance.ref('Monitoring/reset_evaporasi').set(true),
        FirebaseDatabase.instance
            .ref('Monitoring/realtime/reset_evaporasi')
            .set(true),
      ]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Perintah reset evaporasi berhasil dikirim.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal mengirim perintah reset evaporasi: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResettingEvaporasi = false;
        });
      }
    }
  }

  Future<void> _triggerOTA() async {
    if (_isTriggeringOta) return;
    setState(() {
      _isTriggeringOta = true;
    });

    try {
      await Future.wait([
        FirebaseDatabase.instance.ref('Monitoring/ota_trigger').set(true),
        FirebaseDatabase.instance
            .ref('Monitoring/realtime/ota_trigger')
            .set(true),
      ]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Perintah OTA trigger berhasil dikirim.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal mengirim perintah OTA trigger: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTriggeringOta = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.api_rounded, color: Colors.blue.shade700),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Kontrol Database Evaporasi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Tombol ini terhubung ke Firebase untuk reset evaporasi, kontrol selenoid, dan trigger OTA.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: _isResettingEvaporasi ? null : _resetEvaporasi,
                icon: _isResettingEvaporasi
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.refresh_rounded),
                label: Text(
                    _isResettingEvaporasi ? 'Mengirim...' : 'Reset Evaporasi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _isTogglingSelenoid ? null : _toggleSelenoid,
                icon: _isTogglingSelenoid
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _selenoid
                            ? Icons.toggle_on_rounded
                            : Icons.toggle_off_rounded,
                        color: _selenoid ? Colors.green : Colors.grey),
                label:
                    Text(_selenoid ? 'Matikan Selenoid' : 'Nyalakan Selenoid'),
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      _selenoid ? Colors.green.shade700 : Colors.grey.shade800,
                  side: BorderSide(
                      color: _selenoid
                          ? Colors.green.shade300
                          : Colors.grey.shade300),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isTriggeringOta ? null : _triggerOTA,
                icon: _isTriggeringOta
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.cloud_upload_rounded),
                label: Text(_isTriggeringOta ? 'Memanggil OTA...' : 'Trigger OTA'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Status selenoid saat ini: ${_selenoid ? 'AKTIF' : 'MATI'}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
