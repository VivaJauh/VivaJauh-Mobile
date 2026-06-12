import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/loan_service.dart';
import '../services/tenant_service.dart';
import '../utils/formats.dart';
import '../widgets/widgets.dart';
import 'loan_detail_page.dart';
import 'tenant_records_page.dart';

class PrimaryHomePage extends StatefulWidget {
  const PrimaryHomePage({
    required this.session,
    required this.online,
    super.key,
  });

  final AuthSession session;
  final bool online;

  @override
  State<PrimaryHomePage> createState() => _PrimaryHomePageState();
}

class _PrimaryHomePageState extends State<PrimaryHomePage> {
  final _tenantService = const TenantService();
  final _loanService = const LoanService();

  List<MemberSummary> _members = [];
  List<LoanApplication> _applications = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _tenantService.members(widget.session),
        _loanService.list(widget.session),
      ]);
      if (!mounted) return;
      setState(() {
        _members = results[0] as List<MemberSummary>;
        _applications = results[1] as List<LoanApplication>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  List<MemberSummary> get _anggota =>
      _members.where((m) => m.role == 'member').toList();

  @override
  Widget build(BuildContext context) {
    final anggota = _anggota;
    final totalSavings =
        anggota.fold<double>(0, (sum, m) => sum + m.savingsBalance);
    final pendingApplications = _applications
        .where((a) => a.status == LoanStatus.pendingReview)
        .length;
    final recentApplications = _applications.take(3).toList();
    final topMembers = (anggota.toList()
          ..sort((a, b) => b.savingsBalance.compareTo(a.savingsBalance)))
        .take(4)
        .toList();

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (!widget.online) const OfflineBanner(online: false),
          Text(
            'Pengurus Primer',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
          ),
          Text(
            widget.session.koperasiName ?? widget.session.name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                  fontSize: 22,
                ),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 80),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (_error != null)
            EmptyState(
              icon: AppIcons.warning,
              title: 'Gagal memuat',
              message: _error!,
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
            StatCardRow(
              children: [
                StatCard(
                  icon: AppIcons.loanApplication,
                  value: '$pendingApplications',
                  label: 'Pengajuan Berjalan',
                  color: AppColors.warning,
                ),
                StatCard(
                  icon: AppIcons.records,
                  value:
                      '${anggota.fold<int>(0, (sum, m) => sum + m.recordCount)}',
                  label: 'Catatan Anggota',
                  color: AppColors.secondary,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Anggota dengan Simpanan Terbesar',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            if (topMembers.isEmpty)
              const EmptyState(
                icon: AppIcons.members,
                title: 'Belum ada anggota',
                message: 'Anggota yang mendaftar akan muncul di sini.',
              )
            else
              for (final member in topMembers) ...[
                _MemberRow(
                  member: member,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TenantRecordsPage(
                        title: member.name,
                        subtitle:
                            'Catatan tersinkron milik ${member.name} — akses pengurus tercatat.',
                        loader: () => _tenantService.memberRecords(
                          widget.session,
                          member.userId,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            const SizedBox(height: 12),
            Text(
              'Pengajuan Pinjaman Terbaru',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            if (recentApplications.isEmpty)
              const EmptyState(
                icon: AppIcons.loanApplication,
                title: 'Belum ada pengajuan',
                message:
                    'Ajukan pembiayaan untuk anggota lewat tab Pinjaman.',
              )
            else
              for (final app in recentApplications) ...[
                _ApplicationRow(
                  application: app,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LoanDetailPage(
                          session: widget.session,
                          applicationId: app.id,
                        ),
                      ),
                    );
                    if (mounted) _load();
                  },
                ),
                const SizedBox(height: 8),
              ],
          ],
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.onTap});

  final MemberSummary member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(
              AppIcons.members,
              size: 18,
              color: AppColors.primaryDark,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                member.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ),
            Text(
              AppFormats.rupiahCompact(member.savingsBalance),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              AppIcons.chevronRight,
              size: 13,
              color: AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplicationRow extends StatelessWidget {
  const _ApplicationRow({required this.application, required this.onTap});

  final LoanApplication application;
  final VoidCallback onTap;

  Color get _statusColor => switch (application.status) {
        LoanStatus.approved => AppColors.successDark,
        LoanStatus.rejected => AppColors.dangerDark,
        _ => AppColors.warningDark,
      };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(
              AppIcons.loanApplication,
              size: 18,
              color: AppColors.primaryDark,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    application.applicantName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  Text(
                    '${AppFormats.rupiahCompact(application.requestedAmount)} · ${application.targetKoperasi}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              application.status.title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: _statusColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
