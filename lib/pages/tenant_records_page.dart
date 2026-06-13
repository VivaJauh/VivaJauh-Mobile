import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/blocs.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';
import 'record_detail_page.dart';

class TenantRecordsPage extends StatelessWidget {
  const TenantRecordsPage({
    required this.session,
    required this.title,
    required this.subtitle,
    required this.loader,
    super.key,
  });

  final AuthSession session;
  final String title;
  final String subtitle;
  final Future<List<OfflineRecord>> Function() loader;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          FetchBloc<List<OfflineRecord>>(loader)..add(const FetchRequested()),
      child: _TenantRecordsView(
        session: session,
        title: title,
        subtitle: subtitle,
      ),
    );
  }
}

class _TenantRecordsView extends StatelessWidget {
  const _TenantRecordsView({
    required this.session,
    required this.title,
    required this.subtitle,
  });

  final AuthSession session;
  final String title;
  final String subtitle;

  Future<void> _refresh(BuildContext context) {
    final bloc = context.read<FetchBloc<List<OfflineRecord>>>();
    bloc.add(const FetchRequested());
    return bloc.stream
        .firstWhere((state) => state.status != FetchStatus.loading);
  }

  @override
  Widget build(BuildContext context) {
    final state =
        context.watch<FetchBloc<List<OfflineRecord>>>().state;
    final records = state.data ?? const <OfflineRecord>[];
    final showSpinner = state.data == null &&
        (state.status == FetchStatus.loading ||
            state.status == FetchStatus.initial);
    final offline = state.status == FetchStatus.failure &&
        isNetworkError(state.error);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: RefreshIndicator(
        onRefresh: () => _refresh(context),
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            if (offline)
              const OfflineBanner(
                online: false,
                message: 'Mode offline, menampilkan data terakhir',
              ),
            if (showSpinner)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (records.isEmpty)
              EmptyState(
                icon: offline ? AppIcons.offline : AppIcons.emptyInbox,
                title: offline ? 'Data kosong' : 'Belum ada catatan',
                message: offline
                    ? 'Tidak ada data tersimpan dan tidak ada koneksi internet.'
                    : 'Belum ada aktivitas yang tersinkron ke server.',
              )
            else
              for (final record in records) ...[
                RecordTile(
                  record: record,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RecordDetailPage(
                        session: session,
                        record: record,
                        readOnly: true,
                        onUpdateRecord: (_, _) async {},
                        onDeleteRecord: (_) async {},
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
          ],
        ),
      ),
    );
  }
}
