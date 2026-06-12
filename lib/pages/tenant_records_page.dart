import 'package:flutter/material.dart';

import '../models/models.dart';
import '../widgets/widgets.dart';

class TenantRecordsPage extends StatefulWidget {
  const TenantRecordsPage({
    required this.title,
    required this.subtitle,
    required this.loader,
    super.key,
  });

  final String title;
  final String subtitle;
  final Future<List<OfflineRecord>> Function() loader;

  @override
  State<TenantRecordsPage> createState() => _TenantRecordsPageState();
}

class _TenantRecordsPageState extends State<TenantRecordsPage> {
  List<OfflineRecord> _records = [];
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
      final records = await widget.loader();
      if (!mounted) return;
      setState(() {
        _records = records;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Text(
              widget.subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
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
            else if (_records.isEmpty)
              const EmptyState(
                icon: AppIcons.emptyInbox,
                title: 'Belum ada catatan',
                message: 'Belum ada aktivitas yang tersinkron ke server.',
              )
            else
              for (final record in _records) ...[
                RecordTile(record: record),
                const SizedBox(height: 8),
              ],
          ],
        ),
      ),
    );
  }
}
