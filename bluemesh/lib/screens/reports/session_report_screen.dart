import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/attendance_record.dart';
import '../../services/attendance_service.dart';

class SessionReportScreen extends StatefulWidget {
  final int sessionId;
  final String sessionName;

  const SessionReportScreen({
    super.key,
    required this.sessionId,
    required this.sessionName,
  });

  @override
  State<SessionReportScreen> createState() => _SessionReportScreenState();
}

class _SessionReportScreenState extends State<SessionReportScreen> {
  List<AttendanceRecord> _records = [];
  bool _isLoading = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    final attendanceService = Provider.of<AttendanceService>(context, listen: false);
    final list = await attendanceService.getSessionRecords(widget.sessionId);
    if (mounted) {
      setState(() {
        _records = list;
        _isLoading = false;
      });
    }
  }

  void _exportCSV() async {
    setState(() => _isExporting = true);
    try {
      final attendanceService = Provider.of<AttendanceService>(context, listen: false);
      final path = await attendanceService.exportSessionToCSV(widget.sessionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report Exported: $path'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export Failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final presentCount = _records.where((r) => r.status == 'present').length;
    final incompleteCount = _records.where((r) => r.status == 'incomplete').length;
    final absentCount = _records.where((r) => r.status == 'absent').length;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.sessionName} Report', style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Share / Export CSV Report',
            icon: _isExporting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.share_rounded, color: Color(0xFF38BDF8)),
            onPressed: _isExporting ? null : _exportCSV,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Metrics Summary Card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.4)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn('Total Roster', '${_records.length}', Theme.of(context).colorScheme.onSurface),
                      _buildStatColumn('Present', '$presentCount', const Color(0xFF10B981)),
                      _buildStatColumn('Incomplete', '$incompleteCount', const Color(0xFFF59E0B)),
                      _buildStatColumn('Absent', '$absentCount', const Color(0xFFEF4444)),
                    ],
                  ),
                ),

                // Table Header / List
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Student Attendance Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('${_records.length} Records', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),

                Expanded(
                  child: _records.isEmpty
                      ? const Center(child: Text('No attendance records found for this session'))
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _records.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final r = _records[index];

                            Color statusColor;
                            String statusLabel;
                            IconData statusIcon;

                            if (r.status == 'present') {
                              statusColor = const Color(0xFF10B981);
                              statusLabel = 'PRESENT (${r.attendancePercentage}%)';
                              statusIcon = Icons.check_circle_rounded;
                            } else if (r.status == 'incomplete') {
                              statusColor = const Color(0xFFF59E0B);
                              statusLabel = 'LEFT EARLY (${r.attendancePercentage}%)';
                              statusIcon = Icons.warning_rounded;
                            } else {
                              statusColor = const Color(0xFFEF4444);
                              statusLabel = 'ABSENT';
                              statusIcon = Icons.cancel_rounded;
                            }

                            final lastSeenStr = DateFormat('hh:mm:ss a').format(r.lastSeenAt);

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: statusColor.withValues(alpha: 0.15),
                                    child: Icon(statusIcon, color: statusColor, size: 22),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          r.displayName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Roll: ${r.rollNumber} • Duration: ${r.formatAttendedDuration()}',
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          'Fingerprint: ${r.fingerprintVerified ? "Verified 🟢" : "Unverified 🔴"} • Last: $lastSeenStr',
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: statusColor, width: 1),
                                    ),
                                    child: Text(
                                      statusLabel,
                                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }
}
