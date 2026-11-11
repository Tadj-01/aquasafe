import 'package:flutter/material.dart';
import '../../../core/branding/app_branding.dart';
import '../../../shared/widgets/status_badge.dart';

class StatusChangeDialog extends StatefulWidget {
  final String currentStatus;
  final Function(String newStatus, String? note) onConfirm;

  const StatusChangeDialog({
    super.key,
    required this.currentStatus,
    required this.onConfirm,
  });

  @override
  State<StatusChangeDialog> createState() => _StatusChangeDialogState();
}

class _StatusChangeDialogState extends State<StatusChangeDialog> {
  late String _selectedStatus;
  final TextEditingController _noteController = TextEditingController();

  final List<String> _statuses = [
    'NEW',
    'VERIFIED',
    'ASSIGNED',
    'UNDER_REPAIR',
    'RESOLVED',
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentStatus;
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
        'Update Report Status',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: AppBranding.deepNavy,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select new status:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppBranding.secondaryText,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _statuses.map((status) {
                final isSelected = _selectedStatus == status;
                final color = StatusBadge.getStatusColor(status);

                return ChoiceChip(
                  label: Text(
                    StatusBadge.getStatusLabel(status),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : color,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: color,
                  backgroundColor: color.withOpacity(0.1),
                  side: BorderSide(
                    color: color.withOpacity(0.5),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedStatus = status;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            const Text(
              'Audit Note (optional):',
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
                hintText: 'e.g. Verified by field technician on site',
              ),
            ),
          ],
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
              _selectedStatus,
              _noteController.text.trim().isEmpty
                  ? null
                  : _noteController.text.trim(),
            );
          },
          child: const Text('Update Status'),
        ),
      ],
    );
  }
}
