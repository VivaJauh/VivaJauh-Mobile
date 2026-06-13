import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class FetchEvent extends Equatable {
  const FetchEvent();

  @override
  List<Object?> get props => [];
}

class FetchRequested extends FetchEvent {
  const FetchRequested();
}

enum FetchStatus { initial, loading, success, failure }

bool isNetworkError(String? error) {
  if (error == null) return false;
  return error.contains('SocketException') ||
      error.contains('host lookup') ||
      error.contains('dihubungi') ||
      error.contains('ClientException');
}

class FetchState<T> extends Equatable {
  const FetchState({
    this.status = FetchStatus.initial,
    this.data,
    this.error,
  });

  final FetchStatus status;
  final T? data;
  final String? error;

  @override
  List<Object?> get props => [status, data, error];
}

class FetchBloc<T> extends Bloc<FetchEvent, FetchState<T>> {
  FetchBloc(this._loader) : super(FetchState<T>()) {
    on<FetchRequested>(_onRequested);
  }

  final Future<T> Function() _loader;

  Future<void> _onRequested(
    FetchRequested event,
    Emitter<FetchState<T>> emit,
  ) async {
    emit(FetchState<T>(status: FetchStatus.loading, data: state.data));
    try {
      final data = await _loader();
      emit(FetchState<T>(status: FetchStatus.success, data: data));
    } catch (e) {
      emit(
        FetchState<T>(
          status: FetchStatus.failure,
          data: state.data,
          error: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }
}
