import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/machine.dart';
import '../../providers/auth_provider.dart';
import '../../providers/machine_provider.dart';
import '../../providers/maintenance_provider.dart';
import '../../widgets/common_widgets.dart';
import '../maintenance/maintenance_form_screen.dart';
import 'machine_form_screen.dart';

class MachineDetailScreen extends ConsumerStatefulWidget {
  final int machineId;

  const MachineDetailScreen({super.key, required this.machineId});

  @override
  ConsumerState<MachineDetailScreen> createState() => _MachineDetailScreenState();
}

class _MachineDetailScreenState extends ConsumerState<MachineDetailScreen> {
  Machine? _machine;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final machine =
        await context.read<MachineProvider>().getMachine(widget.machineId);
    if (mounted) {
      setState(() {
        _machine = machine;
        _loading = false;
      });
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer'),
        content: const Text('Confirmer la suppression de cette machine ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<MachineProvider>().deleteMachine(widget.machineId);
      if (mounted) Navigator.pop(context);
    }
  }

  String? _getMaintenanceAlert() {
    if (_machine?.lastMaintenanceDate == null) return null;
    final lastDate = DateTime.parse(_machine!.lastMaintenanceDate!);
    final nextDate =
        lastDate.add(Duration(days: _machine!.maintenanceFrequency));
    final daysRemaining =
        nextDate.difference(DateTime.now()).inDays;

    if (daysRemaining < 0) {
      return 'Maintenance en retard de ${-daysRemaining} jours';
    } else if (daysRemaining <= AppConstants.alertDaysBefore) {
      return 'Maintenance prévue dans $daysRemaining jours';
    }
    return 'Prochaine maintenance: ${DateFormat('dd/MM/yyyy').format(nextDate)}';
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(authProvider).isAdmin;
    final alert = _getMaintenanceAlert();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fiche Machine'),
        actions: [
          if (isAdmin && _machine != null) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MachineFormScreen(machine: _machine),
                  ),
                );
                _load();
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _delete,
            ),
          ],
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _machine == null
              ? const EmptyState(
                  icon: Icons.error_outline,
                  message: 'Machine introuvable',
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 36,
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.15),
                                child: const Icon(
                                  Icons.precision_manufacturing,
                                  size: 40,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _machine!.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              StatusChip(status: _machine!.status),
                            ],
                          ),
                        ),
                      ),
                      if (alert != null) ...[
                        const SizedBox(height: 12),
                        AlertBanner(
                          message: alert,
                          isOverdue: alert.contains('retard'),
                        ),
                      ],
                      const SizedBox(height: 16),
                      _InfoTile('Marque', _machine!.brand),
                      _InfoTile('Modèle', _machine!.model),
                      _InfoTile('N° série', _machine!.serialNumber),
                      _InfoTile(
                        'Date installation',
                        DateFormat('dd/MM/yyyy').format(
                          DateTime.parse(_machine!.installationDate),
                        ),
                      ),
                      _InfoTile('Localisation', _machine!.location),
                      _InfoTile(
                        'Fréquence maintenance',
                        '${_machine!.maintenanceFrequency} jours',
                      ),
                      if (_machine!.lastMaintenanceDate != null)
                        _InfoTile(
                          'Dernière maintenance',
                          DateFormat('dd/MM/yyyy').format(
                            DateTime.parse(_machine!.lastMaintenanceDate!),
                          ),
                        ),
                      if (_machine!.description.isNotEmpty)
                        _InfoTile('Description', _machine!.description),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MaintenanceFormScreen(
                                preselectedMachineId: _machine!.id,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.build),
                          label: const Text('Nouvelle intervention'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _MaintenanceHistory(machineId: widget.machineId),
                    ],
                  ),
                ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _MaintenanceHistory extends ConsumerStatefulWidget {
  final int machineId;

  const _MaintenanceHistory({required this.machineId});

  @override
  ConsumerState<_MaintenanceHistory> createState() => _MaintenanceHistoryState();
}

class _MaintenanceHistoryState extends ConsumerState<_MaintenanceHistory> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(maintenanceProvider.notifier).loadMaintenances();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: ref.read(maintenanceProvider.notifier).getByMachine(widget.machineId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historique maintenance',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              const Text('Aucune intervention enregistrée')
            else
              ...items.map((m) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(m.type),
                      subtitle: Text(
                        '${m.date} • ${m.technician}\n${m.solution}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      leading: Icon(
                        m.type == AppConstants.maintenanceTypePreventive
                            ? Icons.schedule
                            : Icons.build,
                        color: AppColors.primary,
                      ),
                    ),
                  )),
          ],
        );
      },
    );
  }
}
