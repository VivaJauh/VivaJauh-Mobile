import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/blocs.dart';
import '../models/models.dart';
import '../services/tenant_service.dart';
import '../utils/formats.dart';
import '../widgets/widgets.dart';
import 'tenant_records_page.dart';

class MembersPage extends StatelessWidget {
  const MembersPage({required this.session, required this.online, super.key});

  final AuthSession session;
  final bool online;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FetchBloc<List<MemberSummary>>(
        () => const TenantService().members(
          session,
          preferCache: !online,
          allowNetwork: online,
        ),
      )..add(const FetchRequested()),
      child: _MembersView(session: session, online: online),
    );
  }
}

class _MembersView extends StatelessWidget {
  const _MembersView({required this.session, required this.online});

  final AuthSession session;
  final bool online;

  Future<void> _refresh(BuildContext context) {
    final bloc = context.read<FetchBloc<List<MemberSummary>>>();
    bloc.add(const FetchRequested());
    return bloc.stream.firstWhere(
      (state) => state.status != FetchStatus.loading,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FetchBloc<List<MemberSummary>>>().state;
    final showSpinner =
        state.data == null &&
        (state.status == FetchStatus.loading ||
            state.status == FetchStatus.initial);
    final offline =
        !online ||
        (state.status == FetchStatus.failure && isNetworkError(state.error));
    final anggota = (state.data ?? const <MemberSummary>[])
        .where((m) => m.role == 'member')
        .toList();
    final totalSavings = anggota.fold<double>(
      0,
      (sum, m) => sum + m.savingsBalance,
    );
    final totalRecords = anggota.fold<int>(0, (sum, m) => sum + m.recordCount);

    return Scaffold(
      appBar: AppBar(
        title: Text('Anggota ${session.koperasiName ?? 'Koperasi'}'),
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(context),
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
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
            else ...[
              StatCardRow(
                children: [
                  StatCard(
                    icon: AppIcons.members,
                    value: '${anggota.length}',
                    label: 'Anggota Aktif',
                    color: AppColors.primary,
                  ),
                  StatCard(
                    icon: AppIcons.savings,
                    value: AppFormats.rupiahCompact(totalSavings),
                    label: 'Total Simpanan',
                    color: AppColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              StatCard(
                icon: AppIcons.records,
                value: '$totalRecords',
                label: 'Total Catatan Anggota',
                color: AppColors.secondary,
              ),
              const SizedBox(height: 16),
              Text(
                'Daftar Anggota',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              if (anggota.isEmpty)
                EmptyState(
                  icon: offline ? AppIcons.offline : AppIcons.members,
                  title: offline ? 'Data kosong' : 'Belum ada anggota',
                  message: offline
                      ? 'Tidak ada data tersimpan dan tidak ada koneksi internet.'
                      : 'Anggota yang mendaftar akan muncul di sini.',
                )
              else
                for (final member in anggota) ...[
                  _MemberTile(
                    member: member,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TenantRecordsPage(
                          session: session,
                          title: member.name,
                          subtitle: 'Catatan tersinkron milik ${member.name}',
                          loader: () => const TenantService().memberRecords(
                            session,
                            member.userId,
                            preferCache: !online,
                            allowNetwork: online,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
            ],
          ],
        ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member, required this.onTap});

  final MemberSummary member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initials = member.name.trim().isEmpty
        ? '?'
        : member.name
              .trim()
              .split(' ')
              .map((word) => word[0])
              .take(2)
              .join()
              .toUpperCase();

    return Semantics(
      button: true,
      label:
          'Anggota ${member.name}, ${member.recordCount} catatan, simpanan ${AppFormats.rupiah(member.savingsBalance)}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${member.recordCount} catatan'
                      '${member.lastActivityAt != null ? ' · terakhir ${AppFormats.dateShort(member.lastActivityAt!)}' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppFormats.rupiahCompact(member.savingsBalance),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  const Text(
                    'Simpanan',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 6),
              const Icon(
                AppIcons.chevronRight,
                size: 14,
                color: AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
