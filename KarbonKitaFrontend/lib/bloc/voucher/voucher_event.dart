/// Event VoucherBloc.
sealed class VoucherEvent {
  const VoucherEvent();
}

/// Muat daftar voucher + saldo eco_points dari backend.
class VouchersLoaded extends VoucherEvent {
  const VouchersLoaded();
}
