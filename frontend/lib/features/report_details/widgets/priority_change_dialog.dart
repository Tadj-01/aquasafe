import 'package:flutter/material.dart';
import '../../../core/branding/app_branding.dart';
import '../../../shared/widgets/priority_badge.dart';

class PriorityChangeDialog extends StatefulWidget {
  final String currentPriority;
  final Function(String newPriority, String? note) onConfirm;

  const PriorityChangeDialog({
    super.key,
    required this.currentPriority,
    required this.onConfirm,
  });

  @override
  State<PriorityChangeDialog> createState() => _PriorityChangeDialogState();
}

class _PriorityChangeDialogState extends State<PriorityChangeDialog> {
  late String _selectedPriority;
  final TextEditingController _noteController = TextEditingController();

  final List<String> _priorities = ['NORMAL', 'HIGH', 'CRITICAL'];

  @override
  void initState() {
    super.initState();
    _selectedPriority = widget.currentPriority;
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
        'Update Leak Priority',
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
              'Select priority level:',
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
              children: _priorities.map((prio) {
                final isSelected = _selectedPriority == prio;
                final color = PriorityBadge.getPriorityColor(prio);

                return ChoiceChip(
                  label: Text(
                    prio,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : color,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: color,
                  backgroundColor: color.withOpacity(0.1),
                  side: BorderSide(color: color.withOpacity(0.5)),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedPriority = prio;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            const Text(
              'Reason / Note (optional):',
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
                hintText: 'e.g. Critical main distribution pipe burst',
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
              _selectedPriority,
              _noteController.text.trim().isEmpty
                  ? null
                  : _noteController.text.trim(),
            );
          },
          child: const Text('Update Priority'),
        ),
      ],
    );
  }
}
