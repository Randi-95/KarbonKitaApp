import 'package:flutter_test/flutter_test.dart';
import 'package:karbon_kita_app/bloc/carbon_calculator/carbon_calculator_cubit.dart';

void main() {
  group('CarbonCalculatorState', () {
    test('default: 8 L Pertalite = 18.48 kg', () {
      const state = CarbonCalculatorState();
      expect(state.jarakKm, 150);
      expect(state.bbmLiter, 8);
      expect(state.emissionKg, closeTo(8 * 2.31, 0.001));
      expect(state.isHighEmission, isFalse);
    });

    test('fallback jarak saat liter 0: (150/40) x 2.31', () {
      const state = CarbonCalculatorState(jarakKm: 150, bbmLiter: 0);
      expect(state.emissionKg, closeTo((150 / 40) * 2.31, 0.001));
    });

    test('solar memakai faktor 2.68', () {
      const state = CarbonCalculatorState(
        bbmLiter: 10,
        fuelType: FuelType.solar,
      );
      expect(state.emissionKg, closeTo(10 * 2.68, 0.001));
    });

    test('emisi > 100 kg memicu rekomendasi tinggi', () {
      const state = CarbonCalculatorState(bbmLiter: 50);
      expect(state.isHighEmission, isTrue);
      expect(state.gaugeProgress, lessThanOrEqualTo(1.0));
    });
  });

  group('CarbonCalculatorCubit', () {
    test('updateJarak/updateBbm/updateFuelType mengubah state', () {
      final cubit = CarbonCalculatorCubit();
      cubit.updateJarak(500);
      expect(cubit.state.jarakKm, 500);
      cubit.updateBbm(20);
      expect(cubit.state.bbmLiter, 20);
      cubit.updateFuelType(FuelType.solar);
      expect(cubit.state.fuelType, FuelType.solar);
      expect(cubit.state.emissionKg, closeTo(20 * 2.68, 0.001));
      cubit.switchCategory(CarbonCategory.listrik);
      expect(cubit.state.category, CarbonCategory.listrik);
      cubit.close();
    });
  });
}
