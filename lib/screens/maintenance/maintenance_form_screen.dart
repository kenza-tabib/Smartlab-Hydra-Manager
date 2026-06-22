import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../models/maintenance.dart';
import '../../providers/auth_provider.dart';
import '../../providers/machine_provider.dart';
import '../../providers/maintenance_provider.dart';

class MaintenanceFormScreen extends StatefulWidget {
  final int? preselectedMachineId;
  final Maintenance? maintenance;

  const MaintenanceFormScreen({
    super.key,
    this.preselectedMachineId,
    this.maintenance,
  });

  @override
  State<MaintenanceFormScreen> createState() => _MaintenanceFormScreenState();
}

class _MaintenanceFormScreenState extends State<MaintenanceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _failureController;
  late final TextEditingController _solutionController;
  late DateTime _date;
  late String _type;
  int? _selectedMachineId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final m = widget.maintenance;
    _failureController = TextEditingController(text: m?.failure ?? '');
    _solutionController = TextEditingController(text: m?.solution ?? '');
    _date = m != null ? DateTime.parse(m.date) : DateTime.now();
    _type = m?.type ?? AppConstants.maintenanceTypeCorrective;
    _selectedMachineId = m?.machineId ?? widget.preselectedMachineId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MachineProvider>().loadMachines();
    });
  }

  @override
  void dispose() {
    _failureController.dispose();
    _solutionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _date = date);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMachineId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez une machine')),
      );
      return;
    }

    setState(() => _saving = true);

    final auth = context.read<AuthProvider>();
    final machineProvider = context.read<MachineProvider>();
    final maintenanceProvider = context.read<MaintenanceProvider>();
    final dateStr = DateFormat('yyyy-MM-dd').format(_date);

    String? nextMaintenance;
    if (_type == AppConstants.maintenanceTypePreventive) {
      final machine =
          await machineProvider.getMachine(_selectedMachineId!);
      if (machine != null) {
        final next = _date.add(Duration(days: machine.maintenanceFrequency));
        nextMaintenance = DateFormat('yyyy-MM-dd').format(next);

        await machineProvider.updateMachine(machine.copyWith(
          lastMaintenanceDate: dateStr,
          status: AppConstants.statusOperational,
        ));
      }
    }

    final maintenance = Maintenance(
      id: widget.maintenance?.id,
      machineId: _selectedMachineId!,
      date: dateStr,
      type: _type,
      failure: _failureController.text.trim(),
      solution: _solutionController.text.trim(),
      technician: auth.currentUser?.username ?? 'Inconnu',
      nextMaintenance: nextMaintenance,
    );

    if (widget.maintenance != null) {
      await maintenanceProvider.updateMaintenance(maintenance);
    } else {
      await maintenanceProvider.addMaintenance(maintenance);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final machines = context.watch<MachineProvider>().machines;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.maintenance != null
              ? 'Modifier intervention'
              : 'Nouvelle intervention',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<int>(
              initialValue: _selectedMachineId,
              decoration: const InputDecoration(labelText: 'Machine *'),
              items: machines
                  .map((m) => DropdownMenuItem(
                        value: m.id,
                        child: Text(m.name),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedMachineId = v),
              validator: (v) => v == null ? 'Requis' : null,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(_date)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Type intervention'),
              items: [
                AppConstants.maintenanceTypePreventive,
                AppConstants.maintenanceTypeCorrective,
              ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _failureController,
              decoration: const InputDecoration(
                labelText: 'Description panne',
                hintText: 'Laisser vide pour maintenance préventive',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _solutionController,
              decoration: const InputDecoration(labelText: 'Solution / Intervention *'),
              maxLines: 3,
              validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}
