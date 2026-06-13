import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../widgets/app_toast.dart';
import 'fetch_bloc.dart';

/// Memunculkan toast saat FetchBloc gagal memuat data, menampilkan pesan
/// singkat dari backend.
class FetchErrorListener<T> extends StatelessWidget {
  const FetchErrorListener({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<FetchBloc<T>, FetchState<T>>(
      listenWhen: (previous, current) =>
          current.status == FetchStatus.failure &&
          (previous.status != FetchStatus.failure ||
              previous.error != current.error),
      listener: (context, state) =>
          showAppToast(context, state.error ?? 'Gagal memuat data', isError: true),
      child: child,
    );
  }
}
