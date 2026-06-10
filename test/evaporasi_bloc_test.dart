import 'package:flutter_test/flutter_test.dart';
import 'package:klimatologiot/screens/monitoring/evaporasi/blocs/evaporasi_bloc.dart';

void main() {
  group('EvaporasiBloc.computeStatus', () {
    test('menggunakan threshold yang diatur untuk status normal', () {
      final result = EvaporasiBloc.computeStatus(
        8.0,
        thresholdRendah: 2.0,
        thresholdTinggi: 10.0,
      );

      expect(result.$1, 'Normal');
      expect(result.$2, isFalse);
    });

    test('menggunakan threshold yang diatur untuk status tinggi', () {
      final result = EvaporasiBloc.computeStatus(
        11.0,
        thresholdRendah: 2.0,
        thresholdTinggi: 10.0,
      );

      expect(result.$1, 'Tinggi');
      expect(result.$2, isTrue);
    });
  });
}
