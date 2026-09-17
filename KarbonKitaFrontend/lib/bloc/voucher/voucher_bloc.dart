import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/auth_exception.dart';
import '../../core/network/voucher_exception.dart';
import '../../data/repositories/voucher_repository.dart';
import 'voucher_event.dart';
import 'voucher_state.dart';

class VoucherBloc extends Bloc<VoucherEvent, VoucherState> {
  VoucherBloc(this._repository) : super(const VoucherState()) {
    on<VouchersLoaded>(_onVouchersLoaded);
    on<MyVouchersLoaded>(_onMyVouchersLoaded);
    on<VoucherClaimSubmitted>(_onClaimSubmitted);
    on<VoucherClaimReset>(_onClaimReset);
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
      emit(
        state.copyWith(
          status: VoucherStatus.loaded,
          vouchers: vouchers,
          ecoPoints: ecoPoints,
        ),
      );
    } on AuthException catch (e) {
      if (e.statusCode == 401) {
        emit(state.copyWith(isUnauthorized: true));
        return;
      }
      emit(
        state.copyWith(status: VoucherStatus.error, errorMessage: e.message),
      );
    } on VoucherException catch (e) {
      if (e.statusCode == 401) {
        emit(state.copyWith(isUnauthorized: true));
        return;
      }
      emit(
        state.copyWith(status: VoucherStatus.error, errorMessage: e.message),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: VoucherStatus.error,
          errorMessage: 'Terjadi kesalahan: $e',
        ),
      );
    }
  }

  Future<void> _onMyVouchersLoaded(
    MyVouchersLoaded event,
    Emitter<VoucherState> emit,
  ) async {
    if (!event.force &&
        state.inventoryStatus == InventoryStatus.loaded &&
        state.myVouchers != null) {
      return;
    }
    final hasCache = state.myVouchers != null;
    emit(
      state.copyWith(
        inventoryStatus: hasCache
            ? state.inventoryStatus
            : InventoryStatus.loading,
        inventoryError: null,
        isUnauthorized: false,
      ),
    );
    try {
      final inventory = await _repository.getMyVouchers();
      emit(
        state.copyWith(
          inventoryStatus: InventoryStatus.loaded,
          myVouchers: inventory,
        ),
      );
    } on AuthException catch (e) {
      if (e.statusCode == 401) {
        emit(state.copyWith(isUnauthorized: true));
        return;
      }
      emit(
        state.copyWith(
          inventoryStatus: hasCache
              ? InventoryStatus.loaded
              : InventoryStatus.error,
          inventoryError: e.message,
        ),
      );
    } on VoucherException catch (e) {
      if (e.statusCode == 401) {
        emit(state.copyWith(isUnauthorized: true));
        return;
      }
      emit(
        state.copyWith(
          inventoryStatus: hasCache
              ? InventoryStatus.loaded
              : InventoryStatus.error,
          inventoryError: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          inventoryStatus: hasCache
              ? InventoryStatus.loaded
              : InventoryStatus.error,
          inventoryError: 'Terjadi kesalahan: $e',
        ),
      );
    }
  }

  Future<void> _onClaimSubmitted(
    VoucherClaimSubmitted event,
    Emitter<VoucherState> emit,
  ) async {
    if (state.claimStatus == ClaimStatus.claiming) return;
    emit(
      state.copyWith(
        claimStatus: ClaimStatus.claiming,
        claimingVoucherId: event.voucherId,
        clearClaim: true,
        isUnauthorized: false,
      ),
    );
    try {
      final result = await _repository.claimVoucher(voucherId: event.voucherId);
      // Klaim mengubah stok + saldo → muat ulang daftar, saldo, dompet.
      final vouchers = await _repository.getVouchers();
      final ecoPoints = await _repository.getEcoPoints();
      final inventory = await _repository.getMyVouchers();
      emit(
        state.copyWith(
          status: VoucherStatus.loaded,
          vouchers: vouchers,
          ecoPoints: ecoPoints,
          inventoryStatus: InventoryStatus.loaded,
          myVouchers: inventory,
          claimStatus: ClaimStatus.success,
          claimingVoucherId: event.voucherId,
          lastClaim: result,
        ),
      );
    } on AuthException catch (e) {
      if (e.statusCode == 401) {
        emit(
          state.copyWith(
            claimStatus: ClaimStatus.idle,
            clearClaim: true,
            isUnauthorized: true,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          claimStatus: ClaimStatus.failure,
          claimingVoucherId: event.voucherId,
          claimErrorMessage: e.message,
        ),
      );
    } on VoucherException catch (e) {
      if (e.statusCode == 401) {
        emit(
          state.copyWith(
            claimStatus: ClaimStatus.idle,
            clearClaim: true,
            isUnauthorized: true,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          claimStatus: ClaimStatus.failure,
          claimingVoucherId: event.voucherId,
          claimErrorMessage: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          claimStatus: ClaimStatus.failure,
          claimingVoucherId: event.voucherId,
          claimErrorMessage: 'Terjadi kesalahan: $e',
        ),
      );
    }
  }

  void _onClaimReset(VoucherClaimReset event, Emitter<VoucherState> emit) {
    emit(state.copyWith(claimStatus: ClaimStatus.idle, clearClaim: true));
  }
}
