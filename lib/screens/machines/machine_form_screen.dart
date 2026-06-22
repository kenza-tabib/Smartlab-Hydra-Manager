import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../models/machine.dart';
import '../../providers/machine_provider.dart';

class MachineFormScreen extends StatefulWidget {
  final Machine? machine;

  const MachineFormScreen({super.key, this.machine});

  @override
  State<MachineFormScreen> createState() => _MachineFormScreenState();
}

class _MachineFormScreenState extends State<MachineFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _serialController;
  late final TextEditingController _locationController;
  late final TextEditingController _descriptionController;
  late DateTime _installationDate;
  late String _status;
  late int _frequency;
  bool _saving = false;

  bool get isEditing => widget.machine != null;

  @override
  void initState() {
    super.initState();
    final m = widget.machine;
    _nameController = TextEditingController(text: m?.name ?? '');
    _brandController = TextEditingController(text: m?.brand ?? 'HydraFacial');
    _modelController = TextEditingController(text: m?.model ?? '');
    _serialController = TextEditingController(text: m?.serialNumber ?? '');
    _locationController = TextEditingController(text: m?.location ?? '');
    _descriptionController = TextEditingController(text: m?.description ?? '');
    _installationDate = m != null
        ? DateTime.parse(m.installationDate)
        : DateTime.now();
    _status = m?.status ?? AppConstants.statusOperational;
    _frequency = m?.maintenanceFrequency ?? 30;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _serialController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _installationDate,
      firstDate: DateTime(2010),
      lastDate: DateTime.now(),
    );
    if (date != null) setState(() => _installationDate = date);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final machine = Machine(
      id: widget.machine?.id,
      name: _nameController.text.trim(),
      brand: _brandController.text.trim(),
      model: _modelController.text.trim(),
      serialNumber: _serialController.text.trim(),
      installationDate: DateFormat('yyyy-MM-dd').format(_installationDate),
      location: _locationController.text.trim(),
      status: _status,
      description: _descriptionController.text.trim(),
      lastMaintenanceDate: widget.machine?.lastMaintenanceDate,
      maintenanceFrequency: _frequency,
    );

    final provider = context.read<MachineProvider>();
    if (isEditing) {
      await provider.updateMachine(machine);
    } else {
      await provider.addMachine(machine);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier machine' : 'Nouvelle machine'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nom *'),
              validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _brandController,
              decoration: const InputDecoration(labelText: 'Marque *'),
              validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _modelController,
              decoration: const InputDecoration(labelText: 'Modèle *'),
              validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _serialController,
              decoration: const InputDecoration(labelText: 'Numéro de série *'),
              validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date d\'installation'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(_installationDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Localisation *'),
              validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Statut'),
              items: [
                AppConstants.statusOperational,
                AppConstants.statusMaintenance,
                AppConstants.statusOutOfService,
              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _frequency,
              decoration: const InputDecoration(
                labelText: 'Fréquence maintenance (jours)',
              ),
              items: AppConstants.maintenanceFrequencies
                  .map((f) => DropdownMenuItem(value: f, child: Text('$f jours')))
                  .toList(),
              onChanged: (v) => setState(() => _frequency = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
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
                  : Text(isEditing ? 'Enregistrer' : 'Ajouter'),
            ),
          ],
        ),
      ),
    );
  }
}
