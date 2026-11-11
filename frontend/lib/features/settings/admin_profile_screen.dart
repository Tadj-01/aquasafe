import 'package:flutter/material.dart';
import '../../core/branding/app_branding.dart';
import '../../core/services/auth_service.dart';
import '../../models/administrator.dart';

class AdminProfileScreen extends StatefulWidget {
  final Administrator admin;

  const AdminProfileScreen({super.key, required this.admin});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isSaving = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.admin.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final newPw = _newPasswordController.text.trim();
    if (newPw.isNotEmpty && newPw != _confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match.'),
          backgroundColor: AppBranding.statusUnderRepair,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updated = await AuthService.updateProfile(
        name: _nameController.text.trim(),
        password: newPw.isNotEmpty ? newPw : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppBranding.statusResolved,
          ),
        );
        Navigator.pop(context, updated);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: AppBranding.statusUnderRepair,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              // Big Profile Avatar
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0369A1)
                      : AppBranding.primaryBlue.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    widget.admin.name.isNotEmpty
                        ? widget.admin.name[0].toUpperCase()
                        : 'A',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: AppBranding.primaryBlue,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Role & Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.admin.isSupervisor
                          ? Colors.purple.withOpacity(0.15)
                          : AppBranding.primaryBlue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.admin.role,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: widget.admin.isSupervisor
                            ? Colors.purple
                            : AppBranding.primaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppBranding.statusResolved.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'ACTIVE & VERIFIED',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppBranding.statusResolved,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Full Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),

              // Email Field (Read-only for security)
              TextFormField(
                initialValue: widget.admin.email,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Email Address (Non-editable)',
                  prefixIcon: Icon(Icons.email_outlined),
                  suffixIcon: Icon(Icons.lock_outline, size: 18),
                ),
              ),
              const SizedBox(height: 24),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Change Password (Optional)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'New Password (min 6 characters)',
                  prefixIcon: const Icon(Icons.key_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
                validator: (val) {
                  if (val != null && val.isNotEmpty && val.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscurePassword,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: Icon(Icons.key_outlined),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Update Profile Details'),
                  onPressed: _isSaving ? null : _handleSave,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
