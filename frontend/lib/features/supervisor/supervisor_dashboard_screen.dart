import 'package:flutter/material.dart';
import '../../core/branding/app_branding.dart';
import '../../core/services/supervisor_service.dart';
import '../../models/administrator.dart';
import '../../shared/widgets/empty_state.dart';
import 'admin_candidate_details_screen.dart';
import 'provision_admin_dialog.dart';

class SupervisorDashboardScreen extends StatefulWidget {
  const SupervisorDashboardScreen({super.key});

  @override
  State<SupervisorDashboardScreen> createState() =>
      _SupervisorDashboardScreenState();
}

class _SupervisorDashboardScreenState extends State<SupervisorDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Administrator> _allAdmins = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAdministrators();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAdministrators() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await SupervisorService.listAdministrators();
      if (mounted) {
        setState(() {
          _allAdmins = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _quickDecision(Administrator admin, String action) async {
    final actionLabel = action == 'APPROVE' ? 'Approve' : 'Reject';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$actionLabel Administrator Request?'),
        content: Text(
            'Are you sure you want to ${actionLabel.toLowerCase()} the account for ${admin.name} (${admin.email})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'APPROVE'
                  ? AppBranding.statusResolved
                  : AppBranding.statusUnderRepair,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(actionLabel.toUpperCase()),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await SupervisorService.reviewApplication(
        adminId: admin.id,
        action: action,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Application for ${admin.name} was ${action == "APPROVE" ? "approved" : "rejected"} successfully.'),
            backgroundColor: action == 'APPROVE'
                ? AppBranding.statusResolved
                : AppBranding.statusUnderRepair,
          ),
        );
      }
      _loadAdministrators();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _toggleActiveState(Administrator admin) async {
    final newActive = !admin.isActive;
    try {
      await SupervisorService.updateAdministrator(admin.id, {
        'is_active': newActive,
      });
      _loadAdministrators();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppBranding.statusUnderRepair,
          ),
        );
      }
    }
  }

  Future<void> _deleteAdmin(Administrator admin) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Administrator'),
        content: Text('Permanently remove ${admin.name} (${admin.email})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppBranding.statusUnderRepair,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupervisorService.deleteAdministrator(admin.id);
        _loadAdministrators();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed: $e'),
              backgroundColor: AppBranding.statusUnderRepair,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingList = _allAdmins.where((a) => a.isPending).toList();
    final approvedList = _allAdmins.where((a) => a.isApproved).toList();
    final rejectedList = _allAdmins.where((a) => a.isRejected).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Supervisor Authority Console'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadAdministrators,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppBranding.primaryBlue,
          indicatorColor: AppBranding.primaryBlue,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Pending'),
                  if (pendingList.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${pendingList.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(text: 'Active (${approvedList.length})'),
            Tab(text: 'Rejected (${rejectedList.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppBranding.primaryBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Provision Admin'),
        onPressed: () async {
          final res = await showDialog<Administrator>(
            context: context,
            builder: (_) => const ProvisionAdminDialog(),
          );
          if (res != null) {
            _loadAdministrators();
          }
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(pendingList, isPendingTab: true),
                    _buildList(approvedList),
                    _buildList(rejectedList),
                  ],
                ),
    );
  }

  Widget _buildList(List<Administrator> admins, {bool isPendingTab = false}) {
    if (admins.isEmpty) {
      return EmptyStateView(
        icon: Icons.shield_outlined,
        title: isPendingTab ? 'No Pending Candidates' : 'No Accounts Found',
        description: isPendingTab
            ? 'When new staff apply via email registration or Google Sign-In, their review cards will appear here.'
            : 'No administrators currently match this category.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAdministrators,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: admins.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final admin = admins[index];
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppBranding.cardBorder),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                if (admin.isPending) {
                  final res = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AdminCandidateDetailsScreen(candidate: admin),
                    ),
                  );
                  if (res == true) _loadAdministrators();
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: admin.isSupervisor
                              ? Colors.purple.withOpacity(0.15)
                              : admin.signupSource == 'GOOGLE'
                                  ? Colors.red.withOpacity(0.12)
                                  : AppBranding.primaryBlue.withOpacity(0.12),
                          child: Text(
                            admin.name.isNotEmpty
                                ? admin.name[0].toUpperCase()
                                : 'A',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: admin.isSupervisor
                                  ? Colors.purple
                                  : admin.signupSource == 'GOOGLE'
                                      ? Colors.red
                                      : AppBranding.primaryBlue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      admin.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (admin.isSupervisor) ...[
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.verified_user_rounded,
                                      size: 16,
                                      color: Colors.purple,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                admin.email,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppBranding.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (val) {
                            if (val == 'toggle') {
                              _toggleActiveState(admin);
                            } else if (val == 'delete') {
                              _deleteAdmin(admin);
                            }
                          },
                          itemBuilder: (ctx) => [
                            PopupMenuItem(
                              value: 'toggle',
                              child: Text(
                                admin.isActive ? 'Deactivate' : 'Activate',
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                'Delete',
                                style: TextStyle(
                                  color: AppBranding.statusUnderRepair,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: admin.isSupervisor
                                    ? Colors.purple.withOpacity(0.12)
                                    : AppBranding.primaryBlue.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                admin.role,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: admin.isSupervisor
                                      ? Colors.purple
                                      : AppBranding.primaryBlue,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppBranding.lightWaterBlue,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Via ${admin.signupSource}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: AppBranding.deepNavy,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (admin.isPending)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  foregroundColor: AppBranding.statusUnderRepair,
                                  side: const BorderSide(
                                      color: AppBranding.statusUnderRepair),
                                ),
                                icon: const Icon(Icons.close_rounded, size: 14),
                                label: const Text('Reject',
                                    style: TextStyle(fontSize: 11)),
                                onPressed: () => _quickDecision(admin, 'REJECT'),
                              ),
                              const SizedBox(width: 6),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  backgroundColor: AppBranding.statusResolved,
                                ),
                                icon: const Icon(Icons.check_rounded, size: 14),
                                label: const Text('Approve',
                                    style: TextStyle(fontSize: 11)),
                                onPressed: () =>
                                    _quickDecision(admin, 'APPROVE'),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.edit_note_rounded,
                                    size: 22, color: AppBranding.primaryBlue),
                                tooltip: 'Details & Wilaya Permissions',
                                onPressed: () async {
                                  final res = await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          AdminCandidateDetailsScreen(
                                              candidate: admin),
                                    ),
                                  );
                                  if (res == true) _loadAdministrators();
                                },
                              ),
                            ],
                          )
                        else
                          Text(
                            admin.isActive ? 'ACTIVE' : 'DEACTIVATED',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: admin.isActive
                                  ? AppBranding.statusResolved
                                  : Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
