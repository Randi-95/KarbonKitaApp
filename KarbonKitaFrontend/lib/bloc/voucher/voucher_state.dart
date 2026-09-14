import '../../models/voucher.dart';

/// Status muat marketplace.
enum VoucherStatus { initial, loading, loaded, error }

class VoucherState {
  const VoucherState({
    this.status = VoucherStatus.initial,
    this.vouchers = const [],
    this.ecoPoints,
    this.errorMessage,
  });

  final VoucherStatus status;
  final List<Voucher> vouchers;
  final int? ecoPoints;
  final String? errorMessage;

  VoucherState copyWith({
    VoucherStatus? status,
    List<Voucher>? vouchers,
    int? ecoPoints,
    String? errorMessage,
  }) {
    return VoucherState(
      status: status ?? this.status,
      vouchers: vouchers ?? this.vouchers,
      ecoPoints: ecoPoints ?? this.ecoPoints,
      errorMessage: errorMessage,
    );
  }
}
