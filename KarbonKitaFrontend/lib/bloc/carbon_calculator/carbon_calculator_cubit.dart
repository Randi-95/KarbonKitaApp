import 'package:flutter_bloc/flutter_bloc.dart';
import 'carbon_calculator_state.dart';

export 'carbon_calculator_state.dart';

class CarbonCalculatorCubit extends Cubit<CarbonCalculatorState> {
  CarbonCalculatorCubit() : super(const CarbonCalculatorState());

  void updateJarak(double value) => emit(state.copyWith(jarakKm: value));

  void updateBbm(double value) => emit(state.copyWith(bbmLiter: value));

  void updateFuelType(FuelType value) => emit(state.copyWith(fuelType: value));

  void switchCategory(CarbonCategory value) =>
      emit(state.copyWith(category: value));
}
