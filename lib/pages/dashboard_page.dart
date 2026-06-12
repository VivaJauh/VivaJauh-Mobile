import 'package:flutter/material.dart';

import '../models/models.dart';
import '../widgets/widgets.dart';
import 'feed_stock_page.dart';
import 'home_page.dart';
import 'livestock_page.dart';
import 'profile_page.dart';
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

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
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
      ProfilePage(
        session: widget.session,
        onLogout: widget.onLogout,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
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
            label: 'Sinkronisasi',
          ),
          NavigationDestination(
            icon: Icon(AppIcons.navProfile),
            selectedIcon: Icon(AppIcons.navProfileActive),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
