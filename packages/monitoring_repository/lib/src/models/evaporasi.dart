// packages/monitoring_repository/lib/src/models/evaporasi.dart

class Evaporasi {
  final double evaporasi;
  final double suhu;
  final double tinggiAir;
  final double acuanPagi;
  final String status;
  final DateTime timestamp;
  final bool sensorError;
  final bool ntpSync;
  final double snapshotCm;
  final double standarTinggi;
  final double batasKritis;
  final int jamPompaMulai;
  final int jamPompaSelesai;
  final bool tempCompActive;
  final double tempCompCoef;
  final double tempRefC;
  final String otaVersion;
  final String otaStatus;
  final bool otaTrigger;
  final bool relayAktif;

  Evaporasi({
    required this.evaporasi,
    required this.suhu,
    required this.tinggiAir,
    required this.acuanPagi,
    required this.status,
    required this.timestamp,
    this.sensorError = false,
    this.ntpSync = false,
    this.snapshotCm = 0.0,
    this.standarTinggi = 0.0,
    this.batasKritis = 0.0,
    this.jamPompaMulai = 0,
    this.jamPompaSelesai = 0,
    this.tempCompActive = false,
    this.tempCompCoef = 0.0,
    this.tempRefC = 0.0,
    this.otaVersion = '-',
    this.otaStatus = '-',
    this.otaTrigger = false,
    this.relayAktif = false,
  });

  static final empty = Evaporasi(
    evaporasi: 0.0,
    suhu: 0.0,
    tinggiAir: 0.0,
    acuanPagi: 0.0,
    status: "Normal",
    timestamp: DateTime.fromMillisecondsSinceEpoch(0),
  );

  factory Evaporasi.fromJson(Map<dynamic, dynamic> json) {
    double toDoubleSafe(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) {
        final s = v.trim();
        final normalized = s.replaceAll(',', '.');
        final match = RegExp(r'[-+]?\d*\.?\d+').firstMatch(normalized);
        if (match != null) {
          return double.tryParse(match.group(0)!) ?? 0.0;
        }
        return double.tryParse(normalized) ?? 0.0;
      }
      return 0.0;
    }

    bool toBoolSafe(dynamic v) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) {
        final lower = v.trim().toLowerCase();
        return lower == 'true' || lower == '1' || lower == 'yes' || lower == 'aktif';
      }
      return false;
    }

    int toIntSafe(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) {
        return int.tryParse(v.trim()) ?? 0;
      }
      return 0;
    }

    String toStringSafe(dynamic v) {
      if (v == null) return '-';
      return v.toString();
    }

    // ── Evaporasi (mm) ───────────────────────────────────
    final evaporasiRaw = toDoubleSafe(
      json['evaporasi_mm'] ??
          json['evaporasi'] ??
          json['evaporasiMm'] ??
          json['evaporation_mm'] ??
          json['evap_mm'] ??
          json['evaporasi_value'] ??
          json['evaporasi_k'],
    );
    final evaporasiVal = evaporasiRaw;

    // ── Suhu (°C) ────────────────────────────────────────
    final suhuRaw = toDoubleSafe(
      json['suhu_air_c'] ??
          json['suhu_air'] ??
          json['suhu'] ??
          json['suhuAir'] ??
          json['temp'] ??
          json['temperature'],
    );
    final suhuVal = (suhuRaw < -50 || suhuRaw > 100) ? -1.0 : suhuRaw;

    // ── Tinggi Air (cm) ──────────────────────────────────
    final tinggiRaw = toDoubleSafe(
      json['tinggi_air_cm'] ??
          json['tinggi_air'] ??
          json['tinggiAir'] ??
          json['tinggiAir_cm'] ??
          json['water_level'] ??
          json['waterLevel'] ??
          json['tinggi_air_m'] ??
          json['tinggiAir_m'],
    );
    final tinggiVal = tinggiRaw;

    // ── Sanity check ─────────────────────────────────────
    final evaporasiFiltered = (evaporasiVal < 0 || evaporasiVal > 50)
        ? 0.0
        : evaporasiVal;
    final tinggiFiltered = (tinggiVal < 0 || tinggiVal > 100) ? 0.0 : tinggiVal;

    // ── Acuan Pagi (cm) ──────────────────────────────────
    final acuanPagiVal = toDoubleSafe(json['acuan_pagi_cm'] ?? 0.0);

    // ── Status ───────────────────────────────────────────
    final statusVal = json['status']?.toString() ?? "Normal";

    final sensorErrorVal = toBoolSafe(
      json['sensor_error'] ??
          json['sensorError'] ??
          json['sensor'] ??
          json['status_sensor'],
    );
    final ntpSyncVal = toBoolSafe(
      json['ntp_sync'] ??
          json['ntpSync'] ??
          json['ntp'],
    );
    final snapshotVal = toDoubleSafe(
      json['snapshot_cm'] ??
          json['snapshot'] ??
          json['acuan_pagi_cm'] ??
          0.0,
    );
    final standarTinggiVal = toDoubleSafe(
      json['standar_tinggi'] ??
          json['standarTinggi'] ??
          json['standard_height'] ??
          0.0,
    );
    final batasKritisVal = toDoubleSafe(
      json['batas_kritis'] ??
          json['batasKritis'] ??
          json['critical_level'] ??
          0.0,
    );
    final jamPompaMulaiVal = toIntSafe(
      json['jam_pompa_mulai'] ??
          json['jamPompaMulai'] ??
          json['pump_start'] ??
          0,
    );
    final jamPompaSelesaiVal = toIntSafe(
      json['jam_pompa_selesai'] ??
          json['jamPompaSelesai'] ??
          json['pump_end'] ??
          0,
    );
    final tempCompActiveVal = toBoolSafe(
      json['temp_comp_aktif'] ??
          json['temp_comp_aktif'] ??
          json['tempCompAktif'] ??
          json['temp_comp_active'] ??
          false,
    );
    final tempCompCoefVal = toDoubleSafe(
      json['temp_comp_koef'] ??
          json['tempCompKoef'] ??
          json['temp_comp_coefficient'] ??
          0.0,
    );
    final tempRefCVal = toDoubleSafe(
      json['temp_ref_c'] ??
          json['tempRefC'] ??
          json['temp_ref'] ??
          0.0,
    );
    final otaVersionVal = toStringSafe(
      json['ota_version'] ?? json['otaVersion'] ?? json['firmware_version'] ?? '-',
    );
    final otaStatusVal = toStringSafe(
      json['ota_status'] ?? json['otaStatus'] ?? '-',
    );
    final otaTriggerVal = toBoolSafe(
      json['ota_trigger'] ?? json['otaTrigger'] ?? false,
    );
    final relayAktifVal = toBoolSafe(
      json['selenoid'] ?? json['selenoid_on'] ?? json['relay'],
    );

    DateTime parseTimestamp(dynamic rawTimestamp) {
      try {
        if (rawTimestamp is int) {
          if (rawTimestamp < 1000000000000) {
            return DateTime.fromMillisecondsSinceEpoch(
              rawTimestamp * 1000,
            ).toLocal();
          }
          return DateTime.fromMillisecondsSinceEpoch(rawTimestamp).toLocal();
        }

        if (rawTimestamp is double) {
          final value = rawTimestamp.toInt();
          if (value < 1000000000000) {
            return DateTime.fromMillisecondsSinceEpoch(value * 1000).toLocal();
          }
          return DateTime.fromMillisecondsSinceEpoch(value).toLocal();
        }

        if (rawTimestamp is String) {
          String s = rawTimestamp.trim();

          final unixValue = int.tryParse(s);
          if (unixValue != null) {
            if (unixValue < 1000000000000) {
              return DateTime.fromMillisecondsSinceEpoch(
                unixValue * 1000,
              ).toLocal();
            }
            return DateTime.fromMillisecondsSinceEpoch(unixValue).toLocal();
          }

          if (s.contains(' ') && !s.contains('T')) {
            s = s.replaceFirst(' ', 'T');
          }

          if (!s.contains('+') && !s.contains('Z') && !s.contains('-', 10)) {
            s = '${s}+07:00';
          }

          final parsed = DateTime.tryParse(s);
          if (parsed != null) return parsed.toLocal();
        }
      } catch (_) {}
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    DateTime timestamp = DateTime.fromMillisecondsSinceEpoch(0);
    final rawTimestamp = json['timestamp'] ?? json['time'] ?? json['datetime'];

    if (rawTimestamp != null) {
      timestamp = parseTimestamp(rawTimestamp);
    } else {
      final waktuStr = json['waktu'] as String?;
      if (waktuStr != null) {
        final parts = waktuStr.split(':');
        if (parts.length >= 2) {
          final jam = int.tryParse(parts[0]) ?? 0;
          final menit = int.tryParse(parts[1]) ?? 0;
          final detik = parts.length >= 3 ? (int.tryParse(parts[2]) ?? 0) : 0;
          final now = DateTime.now();
          timestamp = DateTime(now.year, now.month, now.day, jam, menit, detik);
        }
      }
    }

    return Evaporasi(
      evaporasi: evaporasiFiltered,
      suhu: suhuVal,
      tinggiAir: tinggiFiltered,
      acuanPagi: acuanPagiVal,
      status: statusVal,
      timestamp: timestamp,
      sensorError: sensorErrorVal,
      ntpSync: ntpSyncVal,
      snapshotCm: snapshotVal,
      standarTinggi: standarTinggiVal,
      batasKritis: batasKritisVal,
      jamPompaMulai: jamPompaMulaiVal,
      jamPompaSelesai: jamPompaSelesaiVal,
      tempCompActive: tempCompActiveVal,
      tempCompCoef: tempCompCoefVal,
      tempRefC: tempRefCVal,
      otaVersion: otaVersionVal,
      otaStatus: otaStatusVal,
      otaTrigger: otaTriggerVal,
      relayAktif: relayAktifVal,
    );
  }
}
