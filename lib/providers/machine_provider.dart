import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../database/database_helper.dart';
import '../models/machine.dart';

class MaintenanceAlert {
  final Machine machine;
  final DateTime nextDate;
  final bool isOverdue;
  final int daysRemaining;

  const MaintenanceAlert({
    required this.machine,
    required this.nextDate,
    required this.isOverdue,
    required this.daysRemaining,
  });
}

List<MaintenanceAlert> computeMaintenanceAlerts(List<Machine> machines) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final alerts = <MaintenanceAlert>[];

  for (final machine in machines) {
    if (machine.lastMaintenanceDate == null) continue;

    final lastDate = DateTime.parse(machine.lastMaintenanceDate!);
    final nextDate = lastDate.add(Duration(days: machine.maintenanceFrequency));
    final nextDay = DateTime(nextDate.year, nextDate.month, nextDate.day);
    final daysRemaining = nextDay.difference(today).inDays;

    if (daysRemaining <= AppConstants.alertDaysBefore) {
      alerts.add(MaintenanceAlert(
        machine: machine,
        nextDate: nextDay,
        isOverdue: daysRemaining < 0,
        daysRemaining: daysRemaining,
      ));
    }
  }

  alerts.sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
  return alerts;
}

class MachineProvider extends Notifier<AsyncValue<List<Machine>>> {
  @override
  AsyncValue<List<Machine>> build()   {
     loadMachines();
    return AsyncValue.loading();
  }
  final DatabaseHelper _db = DatabaseHelper.instance;



  int get totalCount => state.value?.length ?? 0;
  int get operationalCount =>
      state.value?.where((m) => m.status == AppConstants.statusOperational).length ?? 0;
  int get maintenanceCount =>
      state.value?.where((m) => m.status == AppConstants.statusMaintenance).length ?? 0;

  List<MaintenanceAlert> get alerts => computeMaintenanceAlerts(state.value ?? []);

  Future<void> loadMachines() async {

    final machines = await _db.getMachines();
    state = AsyncValue.data(machines);

  }

  Future<Machine?> getMachine(int id) => _db.getMachine(id);

  Future<void> addMachine(Machine machine) async {
    await _db.insertMachine(machine);
    await loadMachines();
  }

  Future<void> updateMachine(Machine machine) async {
    await _db.updateMachine(machine);
    await loadMachines();
  }

  Future<void> deleteMachine(int id) async {
    await _db.deleteMachine(id);
    await loadMachines();
  }
}

final machineProvider = NotifierProvider<MachineProvider, AsyncValue<List<Machine>>>(
  () => MachineProvider(),
);