import 'package:flutter/material.dart';
import '../../core/branding/app_branding.dart';
import '../../core/services/report_service.dart';
import '../../core/services/geo_service.dart';
import '../../models/geo_models.dart';
import '../../models/repair_team.dart';
import '../citizen_report/manual_location_picker_screen.dart';

class RepairTeamFormScreen extends StatefulWidget {
  final RepairTeam? team; // null for create mode

  const RepairTeamFormScreen({super.key, this.team});

  @override
  State<RepairTeamFormScreen> createState() => _RepairTeamFormScreenState();
}

class _RepairTeamFormScreenState extends State<RepairTeamFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _leaderNameController;
  late TextEditingController _leaderPhoneController;
  late TextEditingController _phoneController;
  late TextEditingController _descriptionController;
  late TextEditingController _specializationController;
  late TextEditingController _membersCountController;

  bool _isActive = true;
  double? _latitude;
  double? _longitude;
  String? _selectedWilayaCode;
  String? _selectedWilayaName;
  String? _selectedCommuneCode;
  String? _selectedCommuneName;

  List<Wilaya> _wilayas = [];
  List<Commune> _communes = [];
  bool _isLoadingGeo = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.team;
    _nameController = TextEditingController(text: t?.name ?? '');
    _leaderNameController = TextEditingController(text: t?.leaderName ?? '');
    _leaderPhoneController = TextEditingController(text: t?.leaderPhone ?? '');
    _phoneController = TextEditingController(text: t?.phone ?? '');
    _descriptionController = TextEditingController(text: t?.description ?? '');
    _specializationController =
        TextEditingController(text: t?.specialization ?? 'General Leak Repair');
    _membersCountController =
        TextEditingController(text: (t?.membersCount ?? 4).toString());
    _isActive = t?.isActive ?? true;
    _latitude = t?.latitude;
    _longitude = t?.longitude;
    _selectedWilayaCode = t?.wilayaCode;
    _selectedWilayaName = t?.wilayaName;
    _selectedCommuneCode = t?.communeCode;
    _selectedCommuneName = t?.communeName;

    _loadGeo();
  }

  Future<void> _loadGeo() async {
    setState(() => _isLoadingGeo = true);
    final list = await GeoApiService.getWilayas();
    if (mounted) {
      setState(() {
        _wilayas = list;
        _isLoadingGeo = false;
      });
      if (_selectedWilayaCode != null) {
        _loadCommunes(_selectedWilayaCode!);
      }
    }
  }

  Future<void> _loadCommunes(String wCode) async {
    final list = await GeoApiService.getCommunesForWilaya(wCode);
    if (mounted) {
      setState(() {
        _communes = list;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _leaderNameController.dispose();
    _leaderPhoneController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _specializationController.dispose();
    _membersCountController.dispose();
    super.dispose();
  }

  Future<void> _pickLocationOnMap() async {
    final initLat = _latitude ?? 36.7538;
    final initLng = _longitude ?? 3.0588;

    final result = await Navigator.push<Map<String, double>>(
      context,
      MaterialPageRoute(
        builder: (_) => ManualLocationPickerScreen(
          initialLat: initLat,
          initialLng: initLng,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _latitude = result['latitude'];
        _longitude = result['longitude'];
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      'phone': _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      'is_active': _isActive,
      'leader_name': _leaderNameController.text.trim().isEmpty
          ? null
          : _leaderNameController.text.trim(),
      'leader_phone': _leaderPhoneController.text.trim().isEmpty
          ? null
          : _leaderPhoneController.text.trim(),
      'wilaya_code': _selectedWilayaCode,
      'wilaya_name': _selectedWilayaName,
      'commune_code': _selectedCommuneCode,
      'commune_name': _selectedCommuneName,
      'latitude': _latitude,
      'longitude': _longitude,
      'specialization': _specializationController.text.trim().isEmpty
          ? null
          : _specializationController.text.trim(),
      'members_count': int.tryParse(_membersCountController.text.trim()) ?? 1,
    };

    try {
      if (widget.team == null) {
        await ReportApiService.createRepairTeam(data);
      } else {
        await ReportApiService.updateRepairTeam(widget.team!.id, data);
      }
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save team: $e'),
            backgroundColor: AppBranding.statusUnderRepair,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.team != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Repair Team' : 'New Repair Team'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _handleSave,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'SAVE',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppBranding.primaryBlue,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Team Name *',
                  hintText: 'e.g. Algiers Central Intervention Team',
                  prefixIcon: Icon(Icons.groups_rounded),
                ),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _leaderNameController,
                      decoration: const InputDecoration(
                        labelText: 'Team Leader',
                        hintText: 'Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _leaderPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Leader Phone',
                        hintText: '0550...',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Dispatch Line',
                        prefixIcon: Icon(Icons.call_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _membersCountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Staff Count',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _specializationController,
                decoration: const InputDecoration(
                  labelText: 'Specialization',
                  hintText: 'e.g. Main Pipeline, Valve Replacement, Emergency',
                  prefixIcon: Icon(Icons.build_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Wilaya selection
              DropdownButtonFormField<String>(
                value: _selectedWilayaCode,
                decoration: const InputDecoration(
                  labelText: 'Operating Wilaya',
                  prefixIcon: Icon(Icons.map_outlined),
                ),
                items: _wilayas.map((w) {
                  return DropdownMenuItem<String>(
                    value: w.code,
                    child: Text('${w.code} - ${w.nameFr}'),
                  );
                }).toList(),
                onChanged: (code) {
                  setState(() {
                    _selectedWilayaCode = code;
                    if (code != null) {
                      final matches = _wilayas.where((item) => item.code == code);
                      if (matches.isNotEmpty) {
                        _selectedWilayaName = matches.first.nameFr;
                      }
                    }
                    _selectedCommuneCode = null;
                    _selectedCommuneName = null;
                  });
                  if (code != null) _loadCommunes(code);
                },
              ),
              const SizedBox(height: 16),

              // Base Coordinates Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppBranding.lightWaterBlue,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppBranding.softBlue),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: AppBranding.primaryBlue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'HQ / Depot GPS Location',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppBranding.deepNavy,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _latitude != null
                                ? '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}'
                                : 'No base GPS coordinate assigned',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppBranding.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      onPressed: _pickLocationOnMap,
                      child: Text(_latitude == null ? 'Set Pin' : 'Change'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes / Equipment Details',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 16),

              SwitchListTile(
                title: const Text(
                  'Active Status',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Available for emergency leak dispatches'),
                value: _isActive,
                activeColor: AppBranding.primaryBlue,
                onChanged: (val) {
                  setState(() => _isActive = val);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
