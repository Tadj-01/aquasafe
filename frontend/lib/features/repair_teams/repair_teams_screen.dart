import 'package:flutter/material.dart';
import '../../core/branding/app_branding.dart';
import '../../core/services/report_service.dart';
import '../../models/repair_team.dart';
import '../../shared/widgets/empty_state.dart';
import 'repair_team_form_screen.dart';

class RepairTeamsScreen extends StatefulWidget {
  const RepairTeamsScreen({super.key});

  @override
  State<RepairTeamsScreen> createState() => _RepairTeamsScreenState();
}

class _RepairTeamsScreenState extends State<RepairTeamsScreen> {
  List<RepairTeam> _teams = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTeams();
  }

  Future<void> _fetchTeams() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await ReportApiService.getRepairTeams();
      if (mounted) {
        setState(() {
          _teams = list;
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

  Future<void> _deleteTeam(RepairTeam team) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Repair Team'),
        content: Text(
          'Are you sure you want to remove "${team.name}"? If reports are already assigned to this team, it will be safely deactivated instead.',
        ),
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
        await ReportApiService.deleteRepairTeam(team.id);
        _fetchTeams();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Team "${team.name}" removed.')),
          );
        }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Repair Teams & Brigades'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchTeams,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppBranding.primaryBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Team'),
        onPressed: () async {
          final res = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => const RepairTeamFormScreen(),
            ),
          );
          if (res == true) _fetchTeams();
        },
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppBranding.statusUnderRepair),
            const SizedBox(height: 12),
            Text(_error!),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchTeams,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_teams.isEmpty) {
      return EmptyStateView(
        icon: Icons.groups_outlined,
        title: 'No Repair Teams Found',
        description: 'Tap the button below to register a field maintenance brigade.',
        buttonText: 'Add First Team',
        onAction: () async {
          final res = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => const RepairTeamFormScreen(),
            ),
          );
          if (res == true) _fetchTeams();
        },
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchTeams,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: _teams.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final team = _teams[index];
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppBranding.cardBorder),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final res = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RepairTeamFormScreen(team: team),
                  ),
                );
                if (res == true) _fetchTeams();
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: team.isActive
                                ? AppBranding.primaryBlue.withOpacity(0.12)
                                : Colors.grey.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.engineering_rounded,
                            color: team.isActive
                                ? AppBranding.primaryBlue
                                : Colors.grey,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                team.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  if (team.wilayaName != null)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.location_on_outlined,
                                            size: 13,
                                            color: AppBranding.secondaryText),
                                        const SizedBox(width: 2),
                                        Text(
                                          team.wilayaName!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppBranding.secondaryText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (team.specialization != null)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.build_outlined,
                                            size: 13,
                                            color: AppBranding.secondaryText),
                                        const SizedBox(width: 2),
                                        Text(
                                          team.specialization!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppBranding.secondaryText,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (val) {
                            if (val == 'delete') {
                              _deleteTeam(team);
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline,
                                      color: AppBranding.statusUnderRepair,
                                      size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Delete',
                                    style: TextStyle(
                                      color: AppBranding.statusUnderRepair,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (team.leaderName != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person_outline,
                                  size: 15, color: AppBranding.secondaryText),
                              const SizedBox(width: 4),
                              Text(
                                team.leaderName!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        if (team.phone != null || team.leaderPhone != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.phone_outlined,
                                  size: 14, color: AppBranding.secondaryText),
                              const SizedBox(width: 4),
                              Text(
                                team.phone ?? team.leaderPhone ?? '',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppBranding.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: team.isActive
                                ? AppBranding.statusResolved.withOpacity(0.12)
                                : Colors.grey.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            team.isActive ? 'ACTIVE' : 'INACTIVE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: team.isActive
                                  ? AppBranding.statusResolved
                                  : Colors.grey,
                            ),
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
