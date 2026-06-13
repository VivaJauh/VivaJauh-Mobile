import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/models.dart';
import '../../services/loan_service.dart';
import '../../utils/error_messages.dart';

sealed class LoanApplyEvent extends Equatable {
  const LoanApplyEvent();

  @override
  List<Object?> get props => [];
}

class LoanApplySubmitted extends LoanApplyEvent {
  const LoanApplySubmitted({
    required this.applicantName,
    required this.targetKoperasi,
    required this.requestedAmount,
    required this.tenureMonths,
    this.applicantMemberId,
    this.purpose,
  });

  final String applicantName;
  final String targetKoperasi;
  final num requestedAmount;
  final int tenureMonths;
  final String? applicantMemberId;
  final String? purpose;

  @override
  List<Object?> get props => [
    applicantName,
    targetKoperasi,
    requestedAmount,
    tenureMonths,
    applicantMemberId,
    purpose,
  ];
}

class LoanApplyState extends Equatable {
  const LoanApplyState({
    this.submitting = false,
    this.created,
    this.error,
    this.errorId = 0,
  });

  final bool submitting;
  final LoanApplication? created;
  final String? error;
  final int errorId;

  @override
  List<Object?> get props => [submitting, created?.id, error, errorId];
}

class LoanApplyBloc extends Bloc<LoanApplyEvent, LoanApplyState> {
  LoanApplyBloc({
    required LoanService loanService,
    required AuthSession session,
  }) : _loanService = loanService,
       _session = session,
       super(const LoanApplyState()) {
    on<LoanApplySubmitted>(_onSubmitted);
  }

  final LoanService _loanService;
  final AuthSession _session;

  Future<void> _onSubmitted(
    LoanApplySubmitted event,
    Emitter<LoanApplyState> emit,
  ) async {
    emit(const LoanApplyState(submitting: true));
    try {
      final created = await _loanService.create(
        _session,
        applicantName: event.applicantName,
        applicantMemberId: event.applicantMemberId,
        targetKoperasi: event.targetKoperasi,
        requestedAmount: event.requestedAmount,
        tenureMonths: event.tenureMonths,
        purpose: event.purpose,
      );
      emit(LoanApplyState(created: created));
    } catch (e) {
      emit(
        LoanApplyState(
          error: friendlyErrorMessage(e),
          errorId: state.errorId + 1,
        ),
      );
    }
  }
}
