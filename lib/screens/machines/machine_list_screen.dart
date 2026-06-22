import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/machine_provider.dart';
import '../../widgets/common_widgets.dart';
import 'machine_detail_screen.dart';
import 'machine_form_screen.dart';

class MachineListScreen extends StatefulWidget {
  const MachineListScreen({super.key});

  @override
  State<MachineListScreen> createState() => _MachineListScreenState();
}

class _MachineListScreenState extends State<MachineListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MachineProvider>().loadMachines();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MachineProvider>();
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    return Scaffold(
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.machines.isEmpty
              ? EmptyState(
                  icon: Icons.precision_manufacturing_outlined,
                  message: 'Aucune machine enregistrée',
                  actionLabel: isAdmin ? 'Ajouter une machine' : null,
                  onAction: isAdmin
                      ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MachineFormScreen(),
                            ),
                          )
                      : null,
                )
              : RefreshIndicator(
                  onRefresh: provider.loadMachines,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.machines.length,
                    itemBuilder: (context, index) {
                      final machine = provider.machines[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.15),
                            child: const Icon(
                              Icons.precision_manufacturing,
                              color: AppColors.primary,
                            ),
                          ),
                          title: Text(
                            machine.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('${machine.model} • ${machine.serialNumber}'),
                              Text(
                                machine.location,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          trailing: StatusChip(status: machine.status),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  MachineDetailScreen(machineId: machine.id!),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MachineFormScreen()),
              ),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
