import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'blocs/blocs.dart';
import 'models/models.dart';
import 'pages/pages.dart';
import 'services/services.dart';
import 'widgets/widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  final prefs = await SharedPreferences.getInstance();
  runApp(VivaJauhApp(preferences: prefs));
}

class VivaJauhApp extends StatelessWidget {
  const VivaJauhApp({required this.preferences, super.key});

  final SharedPreferences preferences;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create: (_) => AuthService(preferences: preferences),
        ),
        RepositoryProvider(create: (_) => RecordService()),
        RepositoryProvider(
          create: (context) =>
              SyncService(recordService: context.read<RecordService>()),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                AuthBloc(authService: context.read<AuthService>())
                  ..add(const AuthStarted()),
          ),
          BlocProvider(
            create: (context) => RecordsBloc(
              recordService: context.read<RecordService>(),
              syncService: context.read<SyncService>(),
            ),
          ),
        ],
        child: const AppView(),
      ),
    );
  }
}

final _messengerKey = GlobalKey<ScaffoldMessengerState>();

class AppView extends StatelessWidget {
  const AppView({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VivaJauh',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      scaffoldMessengerKey: _messengerKey,
      home: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listenWhen: (previous, current) =>
                previous.session?.userId != current.session?.userId,
            listener: (context, state) {
              final session = state.session;
              context.read<RecordsBloc>().add(
                    session != null
                        ? RecordsStarted(session)
                        : const RecordsCleared(),
                  );
            },
          ),
          BlocListener<RecordsBloc, RecordsState>(
            listenWhen: (previous, current) =>
                current.notice != null && previous.notice != current.notice,
            listener: (context, state) {
              final notice = state.notice!;
              _messengerKey.currentState?.showSnackBar(
                SnackBar(
                  content: Text(notice.message),
                  backgroundColor: notice.isError ? AppColors.danger : null,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
        child: const _RootView(),
      ),
    );
  }
}

class _RootView extends StatelessWidget {
  const _RootView();

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;

    switch (authState.status) {
      case AuthStatus.initial:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AuthStatus.onboarding:
        return OnboardingPage(
          onCompleted: () =>
              context.read<AuthBloc>().add(const AuthOnboardingCompleted()),
        );
      case AuthStatus.unauthenticated:
        return LoginPage(
          loading: authState.submitting,
          errorMessage: authState.error,
          onLogin: (identifier, password) async => context
              .read<AuthBloc>()
              .add(AuthLoginRequested(identifier: identifier, password: password)),
          onRegister: (name, email, password) async =>
              context.read<AuthBloc>().add(
                    AuthRegisterRequested(
                      name: name,
                      email: email,
                      password: password,
                    ),
                  ),
        );
      case AuthStatus.authenticated:
        return _DashboardView(session: authState.session!);
    }
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView({required this.session});

  final AuthSession session;

  @override
  Widget build(BuildContext context) {
    final recordsBloc = context.watch<RecordsBloc>();
    final recordsState = recordsBloc.state;

    return DashboardPage(
      session: session,
      records: recordsState.records,
      syncing: recordsState.syncing,
      online: recordsState.online,
      onLogout: () =>
          context.read<AuthBloc>().add(const AuthLogoutRequested()),
      onAddRecord: (type, payload) async => recordsBloc
          .add(RecordAdded(recordType: type, payload: payload)),
      onUpdateRecord: (type, payload) async => recordsBloc
          .add(RecordCorrectionSubmitted(recordType: type, payload: payload)),
      onDeleteRecord: (record) async =>
          recordsBloc.add(RecordDeletionRequested(record)),
      onSync: () async => recordsBloc.add(const RecordsSyncRequested()),
      onRetryRecord: (record) async =>
          recordsBloc.add(RecordRetryRequested(record)),
      onRefreshRecords: () async =>
          recordsBloc.add(const RecordsRefreshRequested()),
    );
  }
}
