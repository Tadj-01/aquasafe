import 'package:flutter/material.dart';
import '../../core/branding/app_branding.dart';
import '../../core/services/supervisor_service.dart';
import '../../models/administrator.dart';

class ProvisionAdminDialog extends StatefulWidget {
  const ProvisionAdminDialog({super.key});

  @override
  State<ProvisionAdminDialog> createState() => _ProvisionAdminDialogState();
}

class _ProvisionAdminDialogState extends State<ProvisionAdminDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = 'ADMIN';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final newAdmin = await SupervisorService.createAdministrator(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _role,
      );
      if (mounted) {
        Navigator.pop(context, newAdmin);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
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
    return AlertDialog(
      title: const Text('Provision Administrator'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name *'),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email Address *'),
                validator: (val) =>
                    (val == null || !val.contains('@')) ? 'Valid email required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Temporary Password *'),
                validator: (val) =>
                    (val == null || val.length < 6) ? 'Min 6 characters' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: 'ADMIN', child: Text('Standard Admin')),
                  DropdownMenuItem(value: 'SUPERVISOR', child: Text('Supervisor')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _role = val);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('CREATE'),
        ),
      ],
    );
  }
}
