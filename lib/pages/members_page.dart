import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/tenant_service.dart';
import '../utils/formats.dart';
import '../widgets/widgets.dart';
import 'tenant_records_page.dart';

class MembersPage extends StatefulWidget {
  const MembersPage({required this.session, super.key});

  final AuthSession session;

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  final _tenantService = const TenantService();

  List<MemberSummary> _members = [];
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
      final members = await _tenantService.members(widget.session);
      if (!mounted) return;
      setState(() {
        _members = members;
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
    final totalSavings =
        _anggota.fold<double>(0, (sum, m) => sum + m.savingsBalance);
    final totalRecords =
        _anggota.fold<int>(0, (sum, m) => sum + m.recordCount);

    return Scaffold(
      appBar: AppBar(
        title: Text('Anggota ${widget.session.koperasiName ?? 'Koperasi'}'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
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
                    value: '${_anggota.length}',
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
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),
              if (_anggota.isEmpty)
                const EmptyState(
                  icon: AppIcons.members,
                  title: 'Belum ada anggota',
                  message: 'Anggota yang mendaftar akan muncul di sini.',
                )
              else
                for (final member in _anggota) ...[
                  _MemberTile(
                    member: member,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TenantRecordsPage(
                          session: widget.session,
                          title: member.name,
                          subtitle:
                              'Catatan tersinkron milik ${member.name}',
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
