import 'package:flutter/material.dart';
import '../../core/branding/app_branding.dart';
import '../../core/services/supervisor_service.dart';
import '../../models/administrator.dart';

class AdminCandidateDetailsScreen extends StatefulWidget {
  final Administrator candidate;

  const AdminCandidateDetailsScreen({super.key, required this.candidate});

  @override
  State<AdminCandidateDetailsScreen> createState() =>
      _AdminCandidateDetailsScreenState();
}

class _AdminCandidateDetailsScreenState
    extends State<AdminCandidateDetailsScreen> {
  bool _isProcessing = false;
  late String _assignedRole;

  @override
  void initState() {
    super.initState();
    _assignedRole = widget.candidate.role;
  }

  Future<void> _makeDecision(String action) async {
    final isApprove = action == 'APPROVE';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isApprove ? 'Approve Administrator' : 'Reject Applicant'),
        content: Text(
          isApprove
              ? 'Grant system administrator access to ${widget.candidate.name} (${widget.candidate.email}) as $_assignedRole?'
              : 'Reject the registration request from ${widget.candidate.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isApprove
                  ? AppBranding.statusResolved
                  : AppBranding.statusUnderRepair,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    try {
      await SupervisorService.reviewApplication(
        adminId: widget.candidate.id,
        action: action,
        role: _assignedRole,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isApprove
                  ? '${widget.candidate.name} approved successfully!'
                  : 'Applicant rejected.',
            ),
            backgroundColor: isApprove
                ? AppBranding.statusResolved
                : AppBranding.statusUnderRepair,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppBranding.statusUnderRepair,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.candidate;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrator Application'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: c.signupSource == 'GOOGLE'
                          ? Colors.red.withOpacity(0.12)
                          : AppBranding.primaryBlue.withOpacity(0.12),
                      child: Text(
                        c.name.isNotEmpty ? c.name[0].toUpperCase() : 'U',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: c.signupSource == 'GOOGLE'
                              ? Colors.red
                              : AppBranding.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      c.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      c.email,
                      style: const TextStyle(
                        color: AppBranding.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            c.approvalStatus,
                            style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppBranding.lightWaterBlue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Source: ${c.signupSource}',
                            style: const TextStyle(
                              color: AppBranding.deepNavy,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Assign Administrator Role',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: const Text('Regular Administrator'),
                    subtitle: const Text(
                      'Can review leaks, assign repair teams, and update statuses.',
                    ),
                    value: 'ADMIN',
                    groupValue: _assignedRole,
                    onChanged: (val) {
                      if (val != null) setState(() => _assignedRole = val);
                    },
                  ),
                  const Divider(height: 1),
                  RadioListTile<String>(
                    title: const Text('Co-Supervisor Administrator'),
                    subtitle: const Text(
                      'Has all admin powers plus administrator governance.',
                    ),
                    value: 'SUPERVISOR',
                    groupValue: _assignedRole,
                    onChanged: (val) {
                      if (val != null) setState(() => _assignedRole = val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Action Buttons
            if (_isProcessing)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.close_rounded,
                          color: AppBranding.statusUnderRepair),
                      label: const Text(
                        'Reject',
                        style: TextStyle(color: AppBranding.statusUnderRepair),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: AppBranding.statusUnderRepair),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => _makeDecision('REJECT'),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Approve & Activate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppBranding.statusResolved,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => _makeDecision('APPROVE'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
