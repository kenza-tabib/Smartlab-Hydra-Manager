import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/maintenance.dart';
import '../../models/report.dart';
import '../../providers/machine_provider.dart';
import '../../services/pdf_service.dart';

class ReportsScreen extends StatefulWidget {
  final Maintenance? maintenance;

  const ReportsScreen({super.key, this.maintenance});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final PdfService _pdfService = PdfService();
  final _machineController = TextEditingController();
  final _technicianController = TextEditingController();
  final _failureController = TextEditingController();
  final _interventionController = TextEditingController();
  final _resultController = TextEditingController();
  DateTime _date = DateTime.now();
  bool _generating = false;
  File? _generatedFile;

  @override
  void initState() {
    super.initState();
    if (widget.maintenance != null) {
      final m = widget.maintenance!;
      _technicianController.text = m.technician;
      _failureController.text = m.failure;
      _interventionController.text = m.solution;
      _resultController.text = 'Intervention terminée avec succès';
      _date = DateTime.parse(m.date);
      _loadMachineName(m.machineId);
    }
  }

  Future<void> _loadMachineName(int machineId) async {
    final machine =
        await context.read<MachineProvider>().getMachine(machineId);
    if (machine != null && mounted) {
      _machineController.text = machine.name;
    }
  }

  @override
  void dispose() {
    _machineController.dispose();
    _technicianController.dispose();
    _failureController.dispose();
    _interventionController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (_machineController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Renseignez le nom de la machine')),
      );
      return;
    }

    setState(() => _generating = true);

    try {
      final report = Report(
        machineName: _machineController.text.trim(),
        date: DateFormat('dd/MM/yyyy').format(_date),
        technician: _technicianController.text.trim(),
        failureDescription: _failureController.text.trim(),
        intervention: _interventionController.text.trim(),
        result: _resultController.text.trim(),
      );

      final file = await _pdfService.generateReport(report);
      if (mounted) {
        setState(() {
          _generatedFile = file;
          _generating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF généré avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _generating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _share() async {
    if (_generatedFile != null) {
      await _pdfService.shareReport(_generatedFile!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rapport PDF')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(
                    Icons.picture_as_pdf,
                    size: 48,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Génération de rapport',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Créez et exportez un rapport de maintenance',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _machineController,
            decoration: const InputDecoration(
              labelText: 'Machine',
              prefixIcon: Icon(Icons.precision_manufacturing),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date'),
            subtitle: Text(DateFormat('dd/MM/yyyy').format(_date)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) setState(() => _date = date);
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _technicianController,
            decoration: const InputDecoration(
              labelText: 'Technicien',
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _failureController,
            decoration: const InputDecoration(
              labelText: 'Description panne',
              prefixIcon: Icon(Icons.report_problem_outlined),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _interventionController,
            decoration: const InputDecoration(
              labelText: 'Intervention',
              prefixIcon: Icon(Icons.build),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _resultController,
            decoration: const InputDecoration(
              labelText: 'Résultat',
              prefixIcon: Icon(Icons.check_circle_outline),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _generating ? null : _generate,
            icon: _generating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.picture_as_pdf),
            label: const Text('Générer PDF'),
          ),
          if (_generatedFile != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _share,
              icon: const Icon(Icons.share),
              label: const Text('Partager'),
            ),
            const SizedBox(height: 8),
            Text(
              'Fichier: ${_generatedFile!.path.split(Platform.pathSeparator).last}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
