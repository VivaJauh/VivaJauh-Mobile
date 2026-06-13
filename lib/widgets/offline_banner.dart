import 'package:flutter/material.dart';

import 'app_icons.dart';
import 'app_theme.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    required this.online,
    this.pendingCount = 0,
    this.message,
    super.key,
  });

  final bool online;
  final int pendingCount;
  final String? message;

  @override
  Widget build(BuildContext context) {
    if (online) return const SizedBox.shrink();
    final text = message ??
        (pendingCount > 0
            ? 'Mode offline, $pendingCount catatan menunggu sinkronisasi'
            : 'Mode offline, catatan disimpan di perangkat');
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF2DDAE)),
      ),
      child: Row(
        children: [
          const Icon(AppIcons.offline, size: 18, color: AppColors.warningDark),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.warningDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
