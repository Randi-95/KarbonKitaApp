import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/mission_exception.dart';
import '../../data/repositories/mission_repository.dart';
import 'mission_event.dart';
import 'mission_state.dart';

class MissionBloc extends Bloc<MissionEvent, MissionState> {
  MissionBloc(this._repository) : super(const MissionState()) {
    on<MissionsLoaded>(_onMissionsLoaded);
    on<QuizzesLoaded>(_onQuizzesLoaded);
    on<MissionsFiltered>(_onMissionsFiltered);
    on<MobilitySynced>(_onMobilitySynced);
    on<QuizAnswerSubmitted>(_onQuizAnswerSubmitted);
  }

  final MissionRepository _repository;

  Future<void> _onMissionsLoaded(
    MissionsLoaded event,
    Emitter<MissionState> emit,
  ) async {
    emit(state.copyWith(status: MissionStatus.loading, errorMessage: null));
    try {
      final missions = await _repository.getActiveMissions();
      final filtered = state.currentFilter != null
          ? state.getFiltered(state.currentFilter)
          : missions;
      emit(state.copyWith(
        status: MissionStatus.loaded,
        missions: missions,
        filteredMissions: filtered,
      ));
    } on MissionException catch (e) {
      emit(state.copyWith(
        status: MissionStatus.error,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MissionStatus.error,
        errorMessage: 'Terjadi kesalahan: $e',
      ));
    }
  }

  Future<void> _onQuizzesLoaded(
    QuizzesLoaded event,
    Emitter<MissionState> emit,
  ) async {
    emit(state.copyWith(status: MissionStatus.loading, errorMessage: null));
    try {
      final quizzes = await _repository.getSagaQuizzes();
      final filtered = state.currentFilter == 'quiz'
          ? quizzes
          : state.currentFilter != null
              ? state.missions.where((m) => m.category == state.currentFilter).toList()
              : [...state.missions, ...quizzes];
      emit(state.copyWith(
        status: MissionStatus.loaded,
        quizzes: quizzes,
        filteredMissions: filtered,
      ));
    } on MissionException catch (e) {
      emit(state.copyWith(
        status: MissionStatus.error,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MissionStatus.error,
        errorMessage: 'Terjadi kesalahan: $e',
      ));
    }
  }

  Future<void> _onMissionsFiltered(
    MissionsFiltered event,
    Emitter<MissionState> emit,
  ) async {
    final filtered = event.category != null
        ? state.getFiltered(event.category)
        : state.allMissions;
    emit(state.copyWith(
      currentFilter: event.category,
      filteredMissions: filtered,
    ));
  }

  Future<void> _onMobilitySynced(
    MobilitySynced event,
    Emitter<MissionState> emit,
  ) async {
    try {
      await _repository.syncMobility(
        missionId: event.missionId,
        activityType: event.activityType,
        distanceKm: event.distanceKm,
        durationSeconds: event.durationSeconds,
        gpsCoordinatesPath: event.gpsCoordinatesPath,
      );
      // Success - bisa emit event tambahan jika perlu refresh data
    } on MissionException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
      rethrow; // Biarkan UI handle error
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Gagal sinkronisasi: $e'));
      rethrow;
    }
  }

  Future<void> _onQuizAnswerSubmitted(
    QuizAnswerSubmitted event,
    Emitter<MissionState> emit,
  ) async {
    try {
      await _repository.submitQuizAnswer(
        quizId: event.quizId,
        answer: event.answer,
      );
      // Success - bisa emit event tambahan jika perlu refresh data
    } on MissionException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
      rethrow;
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Gagal submit jawaban: $e'));
      rethrow;
    }
  }
}