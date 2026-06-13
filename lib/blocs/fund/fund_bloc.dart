import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/models.dart';
import '../../services/fund_service.dart';
import '../../utils/error_messages.dart';

sealed class FundEvent extends Equatable {
  const FundEvent();

  @override
  List<Object?> get props => [];
}

class FundOverviewRequested extends FundEvent {
  const FundOverviewRequested();
}

class FundPaymentSubmitted extends FundEvent {
  const FundPaymentSubmitted({
    required this.memberId,
    required this.fundType,
    required this.amount,
    this.periodKey,
    this.note,
  });

  final String memberId;
  final CooperativeFundType fundType;
  final double amount;
  final String? periodKey;
  final String? note;

  @override
  List<Object?> get props => [memberId, fundType, amount, periodKey, note];
}

class FundNotice extends Equatable {
  const FundNotice({
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

class FundState extends Equatable {
  const FundState({
    this.loading = true,
    this.overview,
    this.error,
    this.notice,
  });

  final bool loading;
  final FundOverview? overview;
  final String? error;
  final FundNotice? notice;

  FundState copyWith({
    bool? loading,
    FundOverview? overview,
    String? error,
    FundNotice? notice,
  }) => FundState(
    loading: loading ?? this.loading,
    overview: overview ?? this.overview,
    error: error ?? this.error,
    notice: notice ?? this.notice,
  );

  @override
  List<Object?> get props => [loading, overview, error, notice];
}

class FundBloc extends Bloc<FundEvent, FundState> {
  FundBloc({required FundService fundService, required AuthSession session})
    : _fundService = fundService,
      _session = session,
      super(const FundState()) {
    on<FundOverviewRequested>(_onOverviewRequested);
    on<FundPaymentSubmitted>(_onPaymentSubmitted);
  }

  final FundService _fundService;
  final AuthSession _session;
  int _noticeCounter = 0;

  Future<void> _onOverviewRequested(
    FundOverviewRequested event,
    Emitter<FundState> emit,
  ) async {
    emit(FundState(loading: true, overview: state.overview));
    try {
      final overview = await _fundService.overview(_session);
      emit(FundState(loading: false, overview: overview));
    } catch (e) {
      emit(
        FundState(
          loading: false,
          overview: state.overview,
          error: friendlyErrorMessage(e),
        ),
      );
    }
  }

  Future<void> _onPaymentSubmitted(
    FundPaymentSubmitted event,
    Emitter<FundState> emit,
  ) async {
    try {
      await _fundService.recordPayment(
        _session,
        memberId: event.memberId,
        fundType: event.fundType,
        periodKey: event.periodKey,
        amount: event.amount,
        note: event.note,
      );
      emit(
        state.copyWith(
          notice: FundNotice(
            id: ++_noticeCounter,
            message: 'Pembayaran dana berhasil dicatat',
          ),
        ),
      );
      add(const FundOverviewRequested());
    } catch (e) {
      emit(
        state.copyWith(
          notice: FundNotice(
            id: ++_noticeCounter,
            message: friendlyErrorMessage(e),
            isError: true,
          ),
        ),
      );
    }
  }
}
