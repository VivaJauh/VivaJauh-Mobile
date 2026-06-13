import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/models.dart';
import '../../services/loan_service.dart';
import '../../utils/error_messages.dart';

sealed class LoanDetailEvent extends Equatable {
  const LoanDetailEvent();

  @override
  List<Object?> get props => [];
}

class LoanDetailRequested extends LoanDetailEvent {
  const LoanDetailRequested();
}

class LoanDecisionSubmitted extends LoanDetailEvent {
  const LoanDecisionSubmitted({required this.approve, required this.note});

  final bool approve;
  final String note;

  @override
  List<Object?> get props => [approve, note];
}

class LoanDecisionNotice extends Equatable {
  const LoanDecisionNotice({
    required this.id,
    required this.message,
    this.isError = false,
  });

  final int id;
  final String message;
  final bool isError;

  @override
  List<Object?> get props => [id, message, isError];
}

class LoanDetailState extends Equatable {
  const LoanDetailState({
    this.loading = true,
    this.analyzing = false,
    this.deciding = false,
    this.application,
    this.trail,
    this.error,
    this.notice,
  });

  final bool loading;
  final bool analyzing;
  final bool deciding;
  final LoanApplication? application;
  final LoanAuditTrail? trail;
  final String? error;
  final LoanDecisionNotice? notice;

  LoanDetailState copyWith({
    bool? loading,
    bool? analyzing,
    bool? deciding,
    LoanApplication? application,
    LoanAuditTrail? trail,
    String? error,
    LoanDecisionNotice? notice,
  }) => LoanDetailState(
    loading: loading ?? this.loading,
    analyzing: analyzing ?? this.analyzing,
    deciding: deciding ?? this.deciding,
    application: application ?? this.application,
    trail: trail ?? this.trail,
    error: error ?? this.error,
    notice: notice ?? this.notice,
  );

  @override
  List<Object?> get props => [
    loading,
    analyzing,
    deciding,
    application,
    trail,
    error,
    notice,
  ];
}

class LoanDetailBloc extends Bloc<LoanDetailEvent, LoanDetailState> {
  LoanDetailBloc({
    required LoanService loanService,
    required AuthSession session,
    required String applicationId,
  }) : _loanService = loanService,
       _session = session,
       _applicationId = applicationId,
       super(const LoanDetailState()) {
    on<LoanDetailRequested>(_onRequested);
    on<LoanDecisionSubmitted>(_onDecisionSubmitted);
  }

  final LoanService _loanService;
  final AuthSession _session;
  final String _applicationId;
  int _noticeCounter = 0;

  bool get _isSecondary => _session.role == 'secondary_admin';

  Future<LoanAuditTrail?> _loadTrail() async {
    if (!_isSecondary) return null;
    try {
      return await _loanService.auditTrail(_session, _applicationId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _onRequested(
    LoanDetailRequested event,
    Emitter<LoanDetailState> emit,
  ) async {
    emit(state.copyWith(loading: true, analyzing: false));
    try {
      var application = await _loanService.getById(_session, _applicationId);
      if (application.recommendation == null) {
        emit(state.copyWith(loading: true, analyzing: true));
        await _loanService.generateRecommendation(_session, _applicationId);
        application = await _loanService.getById(_session, _applicationId);
      }
      final trail = await _loadTrail();
      emit(
        LoanDetailState(
          loading: false,
          application: application,
          trail: trail,
          notice: state.notice,
        ),
      );
    } catch (e) {
      emit(
        LoanDetailState(
          loading: false,
          application: state.application,
          trail: state.trail,
          error: friendlyErrorMessage(e),
          notice: state.notice,
        ),
      );
    }
  }

  Future<void> _onDecisionSubmitted(
    LoanDecisionSubmitted event,
    Emitter<LoanDetailState> emit,
  ) async {
    emit(state.copyWith(deciding: true));
    try {
      final updated = event.approve
          ? await _loanService.approve(_session, _applicationId, event.note)
          : await _loanService.reject(_session, _applicationId, event.note);
      final trail = await _loadTrail();
      emit(
        LoanDetailState(
          loading: false,
          application: updated,
          trail: trail,
          notice: LoanDecisionNotice(
            id: ++_noticeCounter,
            message: event.approve
                ? 'Pengajuan disetujui'
                : 'Pengajuan ditolak',
          ),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          deciding: false,
          notice: LoanDecisionNotice(
            id: ++_noticeCounter,
            message: friendlyErrorMessage(e),
            isError: true,
          ),
        ),
      );
    }
  }
}
