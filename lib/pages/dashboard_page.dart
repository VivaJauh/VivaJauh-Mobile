import 'package:flutter/material.dart';

import '../models/models.dart';
import '../widgets/widgets.dart';
import 'feed_stock_page.dart';
import 'fund_page.dart';
import 'home_page.dart';
import 'koperasi_monitor_page.dart';
import 'livestock_page.dart';
import 'loan_applications_page.dart';
import 'members_page.dart';
import 'primary_home_page.dart';
import 'profile_page.dart';
import 'secondary_home_page.dart';
import 'sync_queue_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    required this.session,
    required this.records,
    required this.syncing,
    required this.online,
    required this.onLogout,
    required this.onAddRecord,
    required this.onUpdateRecord,
    required this.onDeleteRecord,
    required this.onSync,
    required this.onRetryRecord,
    required this.onRefreshRecords,
    super.key,
  });

  final AuthSession session;
  final List<OfflineRecord> records;
  final bool syncing;
  final bool online;
  final VoidCallback onLogout;
  final Future<void> Function(RecordType, Map<String, dynamic>) onAddRecord;
  final Future<void> Function(RecordType, Map<String, dynamic>) onUpdateRecord;
  final Future<void> Function(OfflineRecord) onDeleteRecord;
  final Future<void> Function() onSync;
  final Future<void> Function(OfflineRecord) onRetryRecord;
  final Future<void> Function() onRefreshRecords;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;

  ProfilePage get _profilePage =>
      ProfilePage(session: widget.session, onLogout: widget.onLogout);

  List<Widget> get _memberPages => [
    HomePage(
      session: widget.session,
      records: widget.records,
      syncing: widget.syncing,
      online: widget.online,
      onAddRecord: widget.onAddRecord,
      onUpdateRecord: widget.onUpdateRecord,
      onDeleteRecord: widget.onDeleteRecord,
      onSync: widget.onSync,
      onRefreshRecords: widget.onRefreshRecords,
    ),
    FeedStockPage(
      session: widget.session,
      records: widget.records,
      online: widget.online,
      onAddRecord: widget.onAddRecord,
      onUpdateRecord: widget.onUpdateRecord,
      onDeleteRecord: widget.onDeleteRecord,
      onRefreshRecords: widget.onRefreshRecords,
    ),
    LivestockPage(
      session: widget.session,
      records: widget.records,
      online: widget.online,
      onAddRecord: widget.onAddRecord,
      onUpdateRecord: widget.onUpdateRecord,
      onDeleteRecord: widget.onDeleteRecord,
      onRefreshRecords: widget.onRefreshRecords,
    ),
    SyncQueuePage(
      records: widget.records,
      syncing: widget.syncing,
      online: widget.online,
      onSync: widget.onSync,
      onRetryRecord: widget.onRetryRecord,
    ),
    FundPage(session: widget.session, online: widget.online),
    _profilePage,
  ];

  static const _memberDestinations = [
    NavigationDestination(
      icon: Icon(AppIcons.navHome),
      selectedIcon: Icon(AppIcons.navHomeActive),
      label: 'Beranda',
    ),
    NavigationDestination(
      icon: Icon(AppIcons.navFeed),
      selectedIcon: Icon(AppIcons.navFeedActive),
      label: 'Pakan',
    ),
    NavigationDestination(
      icon: Icon(AppIcons.navLivestock),
      selectedIcon: Icon(AppIcons.navLivestockActive),
      label: 'Ternak',
    ),
    NavigationDestination(
      icon: Icon(AppIcons.navSync),
      selectedIcon: Icon(AppIcons.navSyncActive),
      label: 'Sinkron',
    ),
    NavigationDestination(
      icon: Icon(AppIcons.savings),
      selectedIcon: Icon(AppIcons.savings),
      label: 'Dana',
    ),
    NavigationDestination(
      icon: Icon(AppIcons.navProfile),
      selectedIcon: Icon(AppIcons.navProfileActive),
      label: 'Profil',
    ),
  ];

  List<Widget> get _primaryPages => [
    PrimaryHomePage(session: widget.session, online: widget.online),
    MembersPage(session: widget.session),
    FundPage(session: widget.session, online: widget.online),
    LoanApplicationsPage(session: widget.session, online: widget.online),
    _profilePage,
  ];

  static const _primaryDestinations = [
    NavigationDestination(
      icon: Icon(AppIcons.navHome),
      selectedIcon: Icon(AppIcons.navHomeActive),
      label: 'Beranda',
    ),
    NavigationDestination(
      icon: Icon(AppIcons.navMembers),
      selectedIcon: Icon(AppIcons.navMembersActive),
      label: 'Anggota',
    ),
    NavigationDestination(
      icon: Icon(AppIcons.savings),
      selectedIcon: Icon(AppIcons.savings),
      label: 'Dana',
    ),
    NavigationDestination(
      icon: Icon(AppIcons.navLoan),
      selectedIcon: Icon(AppIcons.navLoanActive),
      label: 'Pinjaman',
    ),
    NavigationDestination(
      icon: Icon(AppIcons.navProfile),
      selectedIcon: Icon(AppIcons.navProfileActive),
      label: 'Profil',
    ),
  ];

  List<Widget> get _secondaryPages => [
    SecondaryHomePage(session: widget.session, online: widget.online),
    FundPage(session: widget.session, online: widget.online),
    LoanApplicationsPage(session: widget.session, online: widget.online),
    KoperasiMonitorPage(session: widget.session),
    _profilePage,
  ];

  static const _secondaryDestinations = [
    NavigationDestination(
      icon: Icon(AppIcons.navHome),
      selectedIcon: Icon(AppIcons.navHomeActive),
      label: 'Beranda',
    ),
    NavigationDestination(
      icon: Icon(AppIcons.savings),
      selectedIcon: Icon(AppIcons.savings),
      label: 'Dana',
    ),
    NavigationDestination(
      icon: Icon(AppIcons.navLoan),
      selectedIcon: Icon(AppIcons.navLoanActive),
      label: 'Pinjaman',
    ),
    NavigationDestination(
      icon: Icon(AppIcons.navKoperasi),
      selectedIcon: Icon(AppIcons.navKoperasiActive),
      label: 'Koperasi',
    ),
    NavigationDestination(
      icon: Icon(AppIcons.navProfile),
      selectedIcon: Icon(AppIcons.navProfileActive),
      label: 'Profil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final (pages, destinations) = switch (widget.session.role) {
      'primary_admin' => (_primaryPages, _primaryDestinations),
      'secondary_admin' => (_secondaryPages, _secondaryDestinations),
      _ => (_memberPages, _memberDestinations),
    };

    final index = _currentIndex.clamp(0, pages.length - 1);

    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: destinations,
      ),
    );
  }
}
