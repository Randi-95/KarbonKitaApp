import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/voucher_exception.dart';
import '../../data/repositories/voucher_repository.dart';
import 'voucher_event.dart';
import 'voucher_state.dart';

class VoucherBloc extends Bloc<VoucherEvent, VoucherState> {
  VoucherBloc(this._repository) : super(const VoucherState()) {
    on<VouchersLoaded>(_onVouchersLoaded);
  }

  final VoucherRepository _repository;

  Future<void> _onVouchersLoaded(
    VouchersLoaded event,
    Emitter<VoucherState> emit,
  ) async {
    emit(state.copyWith(status: VoucherStatus.loading, errorMessage: null));
    try {
      final vouchers = await _repository.getVouchers();
      final ecoPoints = await _repository.getEcoPoints();
      emit(state.copyWith(
        status: VoucherStatus.loaded,
        vouchers: vouchers,
        ecoPoints: ecoPoints,
      ));
    } on VoucherException catch (e) {
      emit(state.copyWith(
        status: VoucherStatus.error,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: VoucherStatus.error,
        errorMessage: 'Terjadi kesalahan: $e',
      ));
    }
  }
}
