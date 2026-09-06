enum CarbonCategory { listrik, kendaraan, gas }

enum FuelType { pertalite, pertamax, pertamaxTurbo, solar }

extension FuelTypeX on FuelType {
  String get label {
    switch (this) {
      case FuelType.pertalite:
        return 'Pertalite (RON 90)';
      case FuelType.pertamax:
        return 'Pertamax (RON 92)';
      case FuelType.pertamaxTurbo:
        return 'Pertamax Turbo (RON 98)';
      case FuelType.solar:
        return 'Solar / Biosolar';
    }
  }

  /// Faktor emisi standar IPCC default (kg CO2e per liter).
  double get emissionFactor {
    switch (this) {
      case FuelType.pertalite:
      case FuelType.pertamax:
      case FuelType.pertamaxTurbo:
        return 2.31;
      case FuelType.solar:
        return 2.68;
    }
  }
}

class CarbonCalculatorState {
  const CarbonCalculatorState({
    this.category = CarbonCategory.kendaraan,
    this.jarakKm = 150,
    this.bbmLiter = 8,
    this.fuelType = FuelType.pertalite,
  });

  final CarbonCategory category;
  final double jarakKm;
  final double bbmLiter;
  final FuelType fuelType;

  /// Rumus: liter x faktor emisi.
  /// Fallback bila liter == 0 namun jarak > 0: (jarak / 40) x faktor emisi.
  double get emissionKg {
    final factor = fuelType.emissionFactor;
    if (bbmLiter > 0) return bbmLiter * factor;
    if (jarakKm > 0) return (jarakKm / 40) * factor;
    return 0;
  }

  /// Skala maksimum gauge (kg CO2e / bulan).
  static const double gaugeMax = 200;

  double get gaugeProgress =>
      (emissionKg / gaugeMax).clamp(0.0, 1.0).toDouble();

  /// Rekomendasi dinamis sederhana berbasis ambang 100 kg.
  bool get isHighEmission => emissionKg > 100;

  CarbonCalculatorState copyWith({
    CarbonCategory? category,
    double? jarakKm,
    double? bbmLiter,
    FuelType? fuelType,
  }) {
    return CarbonCalculatorState(
      category: category ?? this.category,
      jarakKm: jarakKm ?? this.jarakKm,
      bbmLiter: bbmLiter ?? this.bbmLiter,
      fuelType: fuelType ?? this.fuelType,
    );
  }
}
