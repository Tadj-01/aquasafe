import 'package:flutter/material.dart';
import '../../core/branding/app_branding.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/report_service.dart';
import '../../core/services/supervisor_service.dart';
import '../../models/administrator.dart';
import '../../models/dashboard_stats.dart';
import '../../shared/widgets/empty_state.dart';
import '../report_details/report_details_screen.dart';
import '../supervisor/supervisor_dashboard_screen.dart';
import 'widgets/stat_card.dart';
import 'widgets/recent_report_item.dart';

class AdminDashboardScreen extends StatefulWidget {
  final Function(int targetTab)? onNavigateTab;

  const AdminDashboardScreen({
    super.key,
    this.onNavigateTab,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  DashboardStats? _stats;
  Administrator? _currentAdmin;
  int _pendingAdminCount = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
  }

  Future<void> _fetchDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final statsFuture = ReportApiService.getDashboardStats();
      final adminFuture = AuthService.getCurrentAdmin();

      final stats = await statsFuture;
      final admin = await adminFuture;

      int pendingCount = 0;
      if (admin != null && admin.isSupervisor) {
        try {
          pendingCount = await SupervisorService.getPendingCount();
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _stats = stats;
          _currentAdmin = admin;
          _pendingAdminCount = pendingCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Authority Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Statistics',
            onPressed: _fetchDashboard,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 40, color: AppBranding.statusUnderRepair),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchDashboard,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final stats = _stats!;

    return RefreshIndicator(
      onRefresh: _fetchDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Supervisor Authority Console Card (Visible only to SUPERVISOR)
            if (_currentAdmin != null && _currentAdmin!.isSupervisor) ...[
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: _pendingAdminCount > 0
                        ? Colors.purple
                        : AppBranding.cardBorder,
                    width: _pendingAdminCount > 0 ? 1.5 : 1.0,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      colors: [
                        Colors.purple.shade50.withOpacity(0.5),
                        Colors.white,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings_rounded,
                              color: Colors.purple,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Supervisor Authority Console',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple,
                                  ),
                                ),
                                Text(
                                  _pendingAdminCount > 0
                                      ? '$_pendingAdminCount candidate admin account request${_pendingAdminCount > 1 ? "s" : ""} waiting for your review'
                                      : 'Manage administrator accounts, permissions, and Wilaya authority',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _pendingAdminCount > 0
                                        ? Colors.deepOrange
                                        : AppBranding.secondaryText,
                                    fontWeight: _pendingAdminCount > 0
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: Badge(
                            isLabelVisible: _pendingAdminCount > 0,
                            label: Text('$_pendingAdminCount'),
                            backgroundColor: Colors.red,
                            child: const Icon(Icons.how_to_reg_rounded, size: 18),
                          ),
                          label: Text(
                            _pendingAdminCount > 0
                                ? 'Accept / Review Requests ($_pendingAdminCount Pending)'
                                : 'Open Supervisor Authority Console',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const SupervisorDashboardScreen(),
                              ),
                            );
                            _fetchDashboard();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // KPI Grid
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.6,
              children: [
                StatCard(
                  label: 'Total Reports',
                  count: stats.totalReports,
                  color: AppBranding.deepNavy,
                  icon: Icons.assignment_outlined,
                  onTap: () => widget.onNavigateTab?.call(2), // Reports tab
                ),
                StatCard(
                  label: 'New Reports',
                  count: stats.newReports,
                  color: AppBranding.statusNew,
                  icon: Icons.fiber_new_rounded,
                  onTap: () => widget.onNavigateTab?.call(2),
                ),
                StatCard(
                  label: 'Verified',
                  count: stats.verifiedReports,
                  color: AppBranding.statusVerified,
                  icon: Icons.verified_outlined,
                  onTap: () => widget.onNavigateTab?.call(2),
                ),
                StatCard(
                  label: 'Under Repair',
                  count: stats.underRepairReports,
                  color: AppBranding.statusUnderRepair,
                  icon: Icons.build_circle_outlined,
                  onTap: () => widget.onNavigateTab?.call(2),
                ),
                StatCard(
                  label: 'Assigned',
                  count: stats.assignedReports,
                  color: AppBranding.statusAssigned,
                  icon: Icons.groups_outlined,
                  onTap: () => widget.onNavigateTab?.call(2),
                ),
                StatCard(
                  label: 'Resolved',
                  count: stats.resolvedReports,
                  color: AppBranding.statusResolved,
                  icon: Icons.task_alt_rounded,
                  onTap: () => widget.onNavigateTab?.call(2),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Map Quick Access Card
            Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => widget.onNavigateTab?.call(1), // Map tab
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppBranding.lightWaterBlue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.map_rounded,
                          color: AppBranding.primaryBlue,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Interactive Map View',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppBranding.deepNavy,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${stats.mapPreview.length} active leaks mapped across Algeria',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppBranding.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppBranding.secondaryText,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Top Wilayas (Syscli Algeria)
            if (stats.topWilayas.isNotEmpty) ...[
              const Text(
                'Reports by Wilaya (Syscli Algeria)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppBranding.deepNavy,
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    children: stats.topWilayas.take(5).map((w) {
                      final percentage = stats.totalReports > 0
                          ? (w.count / stats.totalReports)
                          : 0.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${w.wilayaCode ?? ""} - ${w.wilayaName ?? "Unknown"}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppBranding.deepNavy,
                                  ),
                                ),
                                Text(
                                  '${w.count} reports',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppBranding.secondaryText,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percentage,
                                minHeight: 6,
                                backgroundColor: AppBranding.lightWaterBlue,
                                valueColor: const AlwaysStoppedAnimation(
                                  AppBranding.primaryBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Recent Reports Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Leak Reports',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppBranding.deepNavy,
                  ),
                ),
                TextButton(
                  onPressed: () => widget.onNavigateTab?.call(2),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (stats.recentReports.isEmpty)
              const EmptyStateView(
                icon: Icons.check_circle_outline,
                title: 'No reports yet',
                description: 'Citizen leak reports will appear here as soon as they are submitted.',
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: stats.recentReports.length,
                itemBuilder: (context, index) {
                  final report = stats.recentReports[index];
                  return RecentReportItem(
                    report: report,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ReportDetailsScreen(reportId: report.id),
                        ),
                      );
                      _fetchDashboard();
                    },
                  );
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
