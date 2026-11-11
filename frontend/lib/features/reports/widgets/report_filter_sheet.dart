import 'package:flutter/material.dart';
import '../../../core/branding/app_branding.dart';
import '../../../core/services/geo_service.dart';
import '../../../models/geo_models.dart';

class ReportFilterCriteria {
  String? status;
  String? priority;
  String? wilayaCode;
  String? wilayaName;

  ReportFilterCriteria({
    this.status,
    this.priority,
    this.wilayaCode,
    this.wilayaName,
  });

  bool get hasActiveFilters =>
      (status != null && status != 'ALL') ||
      (priority != null && priority != 'ALL') ||
      (wilayaCode != null && wilayaCode != 'ALL');

  void reset() {
    status = null;
    priority = null;
    wilayaCode = null;
    wilayaName = null;
  }
}

class ReportFilterSheet extends StatefulWidget {
  final ReportFilterCriteria initialFilters;
  final Function(ReportFilterCriteria filters) onApply;

  const ReportFilterSheet({
    super.key,
    required this.initialFilters,
    required this.onApply,
  });

  @override
  State<ReportFilterSheet> createState() => _ReportFilterSheetState();
}

class _ReportFilterSheetState extends State<ReportFilterSheet> {
  late String? _status;
  late String? _priority;
  late String? _wilayaCode;
  String? _wilayaName;

  List<Wilaya> _wilayas = [];
  bool _isLoadingWilayas = true;

  final List<String> _statuses = [
    'ALL',
    'NEW',
    'VERIFIED',
    'ASSIGNED',
    'UNDER_REPAIR',
    'RESOLVED',
  ];

  final List<String> _priorities = [
    'ALL',
    'NORMAL',
    'HIGH',
    'CRITICAL',
  ];

  @override
  void initState() {
    super.initState();
    _status = widget.initialFilters.status ?? 'ALL';
    _priority = widget.initialFilters.priority ?? 'ALL';
    _wilayaCode = widget.initialFilters.wilayaCode ?? 'ALL';
    _wilayaName = widget.initialFilters.wilayaName;
    _fetchWilayas();
  }

  Future<void> _fetchWilayas() async {
    try {
      final list = await GeoApiService.getWilayas();
      if (mounted) {
        setState(() {
          _wilayas = list;
          _isLoadingWilayas = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingWilayas = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : AppBranding.pureWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppBranding.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter Reports',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _status = 'ALL';
                        _priority = 'ALL';
                        _wilayaCode = 'ALL';
                        _wilayaName = null;
                      });
                    },
                    child: const Text('Reset All'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Status filter
              const Text(
                'Status',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _statuses.map((s) {
                  final isSelected = _status == s;
                  return ChoiceChip(
                    label: Text(s.replaceAll('_', ' ')),
                    selected: isSelected,
                    selectedColor: AppBranding.primaryBlue,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _status = s);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // Priority filter
              const Text(
                'Priority',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _priorities.map((p) {
                  final isSelected = _priority == p;
                  return ChoiceChip(
                    label: Text(p),
                    selected: isSelected,
                    selectedColor: AppBranding.primaryBlue,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _priority = p);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // Wilaya filter (Syscli Algeria)
              const Text(
                'Wilaya (Syscli Algeria)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              if (_isLoadingWilayas)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  value: _wilayaCode,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'ALL',
                      child: Text('All Wilayas (Algeria)'),
                    ),
                    ..._wilayas.map((w) {
                      return DropdownMenuItem(
                        value: w.code,
                        child: Text(
                          '${w.code} - ${w.nameFr} (${w.nameAr})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _wilayaCode = val;
                      if (val != null && val != 'ALL') {
                        final found = _wilayas.firstWhere((w) => w.code == val);
                        _wilayaName = found.nameFr;
                      } else {
                        _wilayaName = null;
                      }
                    });
                  },
                ),

              const SizedBox(height: 24),

              // Apply button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onApply(
                      ReportFilterCriteria(
                        status: _status == 'ALL' ? null : _status,
                        priority: _priority == 'ALL' ? null : _priority,
                        wilayaCode: _wilayaCode == 'ALL' ? null : _wilayaCode,
                        wilayaName: _wilayaName,
                      ),
                    );
                  },
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
