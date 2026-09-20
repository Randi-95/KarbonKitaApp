import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/auth_exception.dart';
import '../../core/network/voucher_exception.dart';
import '../../data/repositories/profile_repository.dart';
import 'activity_event.dart';
import 'activity_state.dart';

/// BLoC aktivitas terbaru profil: `GET /api/user/activities`.
class ActivityBloc extends Bloc<ActivityEvent, ActivityState> {
  ActivityBloc(this._repository) : super(const ActivityState()) {
    on<ActivityLoaded>(_onLoaded);
    on<ActivityRefreshed>(_onRefreshed);
  }

  final ProfileRepository _repository;

  Future<void> _onLoaded(
    ActivityLoaded event,
    Emitter<ActivityState> emit,
  ) async {
    if (state.status == ActivityStatus.loaded) return;
    await _load(emit);
  }

  Future<void> _onRefreshed(
    ActivityRefreshed event,
    Emitter<ActivityState> emit,
  ) async {
    await _load(emit);
  }

  Future<void> _load(Emitter<ActivityState> emit) async {
    final hasCache = state.items.isNotEmpty;
    emit(
      state.copyWith(
        status: hasCache ? state.status : ActivityStatus.loading,
        errorMessage: null,
        isUnauthorized: false,
      ),
    );
    try {
      final items = await _repository.getActivities();
      emit(state.copyWith(status: ActivityStatus.loaded, items: items));
    } on AuthException catch (e) {
      if (e.statusCode == 401) {
        emit(state.copyWith(isUnauthorized: true));
        return;
      }
      emit(
        state.copyWith(
          status: hasCache ? ActivityStatus.loaded : ActivityStatus.error,
          errorMessage: e.message,
        ),
      );
    } on VoucherException catch (e) {
      if (e.statusCode == 401) {
        emit(state.copyWith(isUnauthorized: true));
        return;
      }
      emit(
        state.copyWith(
          status: hasCache ? ActivityStatus.loaded : ActivityStatus.error,
          errorMessage: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: hasCache ? ActivityStatus.loaded : ActivityStatus.error,
          errorMessage: 'Terjadi kesalahan: $e',
        ),
      );
    }
  }
}
