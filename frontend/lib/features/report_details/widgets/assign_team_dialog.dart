import 'package:flutter/material.dart';
import '../../../core/branding/app_branding.dart';
import '../../../models/repair_team.dart';

class AssignTeamDialog extends StatefulWidget {
  final List<RepairTeam> teams;
  final String? currentlyAssignedTeamId;
  final Function(String? teamId, String? note) onConfirm;

  const AssignTeamDialog({
    super.key,
    required this.teams,
    this.currentlyAssignedTeamId,
    required this.onConfirm,
  });

  @override
  State<AssignTeamDialog> createState() => _AssignTeamDialogState();
}

class _AssignTeamDialogState extends State<AssignTeamDialog> {
  String? _selectedTeamId;
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedTeamId = widget.currentlyAssignedTeamId;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Assign Repair Team',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: AppBranding.deepNavy,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select team to dispatch:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppBranding.secondaryText,
                ),
              ),
              const SizedBox(height: 10),
              RadioListTile<String?>(
                title: const Text('None (Unassigned)',
                    style: TextStyle(fontSize: 13)),
                value: null,
                groupValue: _selectedTeamId,
                onChanged: (val) {
                  setState(() {
                    _selectedTeamId = val;
                  });
                },
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              ...widget.teams.map((team) {
                return RadioListTile<String?>(
                  title: Text(team.name,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: team.description != null
                      ? Text(team.description!,
                          style: const TextStyle(fontSize: 11))
                      : null,
                  value: team.id,
                  groupValue: _selectedTeamId,
                  onChanged: (val) {
                    setState(() {
                      _selectedTeamId = val;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                );
              }),
              const SizedBox(height: 16),
              const Text(
                'Assignment instructions / note (optional):',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppBranding.secondaryText,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'e.g. Dispatched with pressure diagnostic tools',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onConfirm(
              _selectedTeamId,
              _noteController.text.trim().isEmpty
                  ? null
                  : _noteController.text.trim(),
            );
          },
          child: const Text('Confirm Assignment'),
        ),
      ],
    );
  }
}
