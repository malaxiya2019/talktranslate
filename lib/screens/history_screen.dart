import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/call.dart';
import '../providers/app_provider.dart';

/// 通话记录页面
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('通话记录'), centerTitle: true),
      body: Consumer<AppProvider>(
        builder: (context, p, _) {
          final records = p.callHistory;
          if (records.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey[200]),
                  const SizedBox(height: 12),
                  Text(
                    '暂无通话记录',
                    style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '完成一次通话后记录会自动保存',
                    style: TextStyle(fontSize: 13, color: Colors.grey[300]),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: records.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
            itemBuilder: (_, i) => _CallRecordTile(record: records[i]),
          );
        },
      ),
    );
  }
}

class _CallRecordTile extends StatelessWidget {
  final CallRecord record;
  const _CallRecordTile({required this.record});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue.withValues(alpha: 0.1),
        child: Text(
          record.peerName.substring(
            (record.peerName.length - 2).clamp(0, record.peerName.length),
          ),
          style: TextStyle(fontSize: 13, color: Colors.blue[700]),
        ),
      ),
      title: Text(
        record.peerName,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      subtitle: Row(
        children: [
          Icon(Icons.access_time, size: 12, color: Colors.grey[400]),
          const SizedBox(width: 4),
          Text(
            _formatDate(record.startTime),
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          const SizedBox(width: 12),
          Icon(Icons.timer_outlined, size: 12, color: Colors.grey[400]),
          const SizedBox(width: 4),
          Text(
            _formatDuration(record.durationSeconds),
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
      trailing:
          record.lastTranscript != null && record.lastTranscript!.isNotEmpty
          ? Icon(Icons.translate, size: 18, color: Colors.green[300])
          : null,
      onTap: () => _showDetail(context),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              record.peerName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _infoRow(Icons.access_time, _formatDate(record.startTime)),
            const SizedBox(height: 4),
            _infoRow(
              Icons.timer_outlined,
              '时长 ${_formatDuration(record.durationSeconds)}',
            ),
            if (record.lastTranscript != null &&
                record.lastTranscript!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                '最后翻译',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                record.lastTranscript!,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[400]),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inDays < 1)
      return '今天 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (diff.inDays == 1)
      return '昨天 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}秒';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}分${s}秒';
  }
}
