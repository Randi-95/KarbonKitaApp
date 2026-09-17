import '../../models/my_voucher.dart';
import '../../models/voucher.dart';

/// Status muat marketplace.
enum VoucherStatus { initial, loading, loaded, error }

/// Status muat inventaris dompet (independen dari marketplace).
enum InventoryStatus { initial, loading, loaded, error }

/// Status proses klaim satu voucher.
enum ClaimStatus { idle, claiming, success, failure }

class VoucherState {
  const VoucherState({
    this.status = VoucherStatus.initial,
    this.vouchers = const [],
    this.ecoPoints,
    this.errorMessage,
    this.inventoryStatus = InventoryStatus.initial,
    this.myVouchers,
    this.inventoryError,
    this.claimStatus = ClaimStatus.idle,
    this.claimingVoucherId,
    this.lastClaim,
    this.claimErrorMessage,
    this.isUnauthorized = false,
  });

  final VoucherStatus status;
  final List<Voucher> vouchers;
  final int? ecoPoints;
  final String? errorMessage;

  final InventoryStatus inventoryStatus;
  final MyVoucherInventory? myVouchers;
  final String? inventoryError;

  final ClaimStatus claimStatus;
  final int? claimingVoucherId;
  final ClaimResult? lastClaim;
  final String? claimErrorMessage;

  /// True bila backend 401 — UI harus logout, bukan sekadar retry.
  final bool isUnauthorized;

  VoucherState copyWith({
    VoucherStatus? status,
    List<Voucher>? vouchers,
    int? ecoPoints,
    String? errorMessage,
    InventoryStatus? inventoryStatus,
    MyVoucherInventory? myVouchers,
    String? inventoryError,
    ClaimStatus? claimStatus,
    int? claimingVoucherId,
    ClaimResult? lastClaim,
    bool clearClaim = false,
    String? claimErrorMessage,
    bool? isUnauthorized,
  }) {
    return VoucherState(
      status: status ?? this.status,
      vouchers: vouchers ?? this.vouchers,
      ecoPoints: ecoPoints ?? this.ecoPoints,
      errorMessage: errorMessage,
      inventoryStatus: inventoryStatus ?? this.inventoryStatus,
      myVouchers: myVouchers ?? this.myVouchers,
      inventoryError: inventoryError,
      claimStatus: claimStatus ?? this.claimStatus,
      claimingVoucherId: clearClaim
          ? null
          : (claimingVoucherId ?? this.claimingVoucherId),
      lastClaim: clearClaim ? null : (lastClaim ?? this.lastClaim),
      claimErrorMessage: clearClaim ? null : claimErrorMessage,
      isUnauthorized: isUnauthorized ?? this.isUnauthorized,
    );
  }
}
