/// Event VoucherBloc.
sealed class VoucherEvent {
  const VoucherEvent();
}

/// Muat daftar voucher + saldo eco_points dari backend.
class VouchersLoaded extends VoucherEvent {
  const VouchersLoaded();
}

/// Muat inventaris dompet (active/used/expired) dari backend.
class MyVouchersLoaded extends VoucherEvent {
  const MyVouchersLoaded({this.force = false});

  final bool force;
}

/// Tukar poin dengan satu voucher.
class VoucherClaimSubmitted extends VoucherEvent {
  const VoucherClaimSubmitted(this.voucherId);

  final int voucherId;
}

/// Reset status klaim setelah dialog hasil ditutup.
class VoucherClaimReset extends VoucherEvent {
  const VoucherClaimReset();
}
