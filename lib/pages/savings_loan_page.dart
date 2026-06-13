import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/aggregator.dart';
import '../utils/formats.dart';
import '../widgets/widgets.dart';
import 'loan_applications_page.dart';
import 'record_detail_page.dart';
import 'record_form_page.dart';

class SavingsLoanPage extends StatefulWidget {
  const SavingsLoanPage({
    required this.session,
    required this.records,
    required this.online,
    required this.onAddRecord,
    required this.onUpdateRecord,
    required this.onDeleteRecord,
    required this.onRefreshRecords,
    this.initialLoanTab = false,
    super.key,
  });

  final AuthSession session;
  final List<OfflineRecord> records;
  final bool online;
  final Future<void> Function(RecordType, Map<String, dynamic>) onAddRecord;
  final Future<void> Function(RecordType, Map<String, dynamic>) onUpdateRecord;
  final Future<void> Function(OfflineRecord) onDeleteRecord;
  final Future<void> Function() onRefreshRecords;
  final bool initialLoanTab;

  @override
  State<SavingsLoanPage> createState() => _SavingsLoanPageState();
}

class _SavingsLoanPageState extends State<SavingsLoanPage> {
  late bool _loanTab;

  @override
  void initState() {
    super.initState();
    _loanTab = widget.initialLoanTab;
  }

  SavingsLoanSummary get _summary =>
      Aggregator.computeSavingsLoan(widget.records);

  RecordType get _fabType =>
      _loanTab ? RecordType.loanRepayment : RecordType.savingsTransaction;

  @override
  Widget build(BuildContext context) {
    final summary = _summary;

    return Scaffold(
      appBar: AppBar(title: const Text('Simpan Pinjam')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNew,
        child: const Icon(AppIcons.add),
      ),
      body: RefreshIndicator(
        onRefresh: widget.onRefreshRecords,
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 128),
          children: [
            _SavingsHeroCard(balance: summary.savingsBalance),
            const SizedBox(height: 16),
            StatCardRow(
              children: [
                StatCard(
                  icon: AppIcons.stockIn,
                  value: AppFormats.rupiahCompact(summary.totalDeposits),
                  label: 'Total Setor',
                  color: AppColors.success,
                ),
                StatCard(
                  icon: AppIcons.withdraw,
                  value: AppFormats.rupiahCompact(summary.totalWithdrawals),
                  label: 'Total Tarik',
                  color: AppColors.danger,
                ),
              ],
            ),
            const SizedBox(height: 8),
            StatCardRow(
              children: [
                StatCard(
                  icon: AppIcons.loan,
                  value: AppFormats.rupiahCompact(summary.totalRepayments),
                  label: 'Total Cicilan',
                  color: AppColors.secondary,
                ),
                StatCard(
                  icon: AppIcons.members,
                  value: '${summary.savingsByMember.length}',
                  label: 'Anggota',
                  color: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _LoanApplyCta(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LoanApplicationsPage(
                    session: widget.session,
                    online: widget.online,
                    onAddRecord: widget.onAddRecord,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Simpanan')),
                ButtonSegment(value: true, label: Text('Cicilan')),
              ],
              selected: {_loanTab},
              onSelectionChanged: (s) => setState(() => _loanTab = s.first),
            ),
            const SizedBox(height: 16),
            if (!_loanTab && summary.savingsByMember.isNotEmpty) ...[
              SectionCard(
                child: HBarChart(
                  title: 'Saldo per Anggota',
                  unit: '',
                  items:
                      (summary.savingsByMember.entries.toList()
                            ..sort((a, b) => b.value.compareTo(a.value)))
                          .take(8)
                          .map(
                            (e) => HBarItem(
                              label: e.key,
                              value: e.value,
                              color: AppColors.primary,
                            ),
                          )
                          .toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_loanTab && summary.repaymentsByMember.isNotEmpty) ...[
              SectionCard(
                child: HBarChart(
                  title: 'Cicilan per Anggota',
                  unit: '',
                  items:
                      (summary.repaymentsByMember.entries.toList()
                            ..sort((a, b) => b.value.compareTo(a.value)))
                          .take(8)
                          .map(
                            (e) => HBarItem(
                              label: e.key,
                              value: e.value,
                              color: AppColors.secondary,
                            ),
                          )
                          .toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              _loanTab ? 'Riwayat Cicilan' : 'Riwayat Simpanan',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            ..._historyList(
              _loanTab ? summary.loanHistory : summary.savingsHistory,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _historyList(List<OfflineRecord> history) {
    if (history.isEmpty) {
      return [
        EmptyState(
          icon: AppIcons.emptyInbox,
          title: 'Belum ada riwayat',
          message: 'Tambah catatan baru dengan tombol + di bawah.',
        ),
      ];
    }
    return history
        .take(20)
        .map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RecordTile(
              record: r,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecordDetailPage(
                    session: widget.session,
                    record: r,
                    onUpdateRecord: widget.onUpdateRecord,
                    onDeleteRecord: widget.onDeleteRecord,
                  ),
                ),
              ),
            ),
          ),
        )
        .toList();
  }

  Future<void> _addNew() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecordFormPage(
          session: widget.session,
          recordType: _fabType,
          onSave: widget.onAddRecord,
          records: widget.records,
        ),
      ),
    );
  }
}

class _LoanApplyCta extends StatelessWidget {
  const _LoanApplyCta({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Buka pengajuan pinjaman dengan analisis lintas koperasi',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withAlpha(70)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  AppIcons.loanApplication,
                  color: AppColors.primaryDark,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pengajuan Pinjaman',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Analisis riwayat anggota lintas koperasi',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                AppIcons.chevronRight,
                size: 14,
                color: AppColors.primaryDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavingsHeroCard extends StatelessWidget {
  const _SavingsHeroCard({required this.balance});

  final double balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(AppIcons.savings, color: Colors.white70, size: 18),
              const SizedBox(width: 6),
              Text(
                'Total Saldo Simpanan',
                style: TextStyle(
                  color: Colors.white.withAlpha(200),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            AppFormats.rupiah(balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
