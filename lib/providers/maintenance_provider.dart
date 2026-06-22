import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database_helper.dart';
import '../models/maintenance.dart';

/// Immutable state held by the MaintenanceNotifier.
class MaintenanceState {
  final List<Maintenance> maintenances;
  final bool isLoading;
  final List<Map<String, dynamic>> monthlyData;
  final List<Map<String, dynamic>> failureData;

  const MaintenanceState({
    this.maintenances = const [],
    this.isLoading = false,
    this.monthlyData = const [],
    this.failureData = const [],
  });

  int get totalCount => maintenances.length;

  MaintenanceState copyWith({
    List<Maintenance>? maintenances,
    bool? isLoading,
    List<Map<String, dynamic>>? monthlyData,
    List<Map<String, dynamic>>? failureData,
  }) {
    return MaintenanceState(
      maintenances: maintenances ?? this.maintenances,
      isLoading: isLoading ?? this.isLoading,
      monthlyData: monthlyData ?? this.monthlyData,
      failureData: failureData ?? this.failureData,
    );
  }
}

/// Provider for the DatabaseHelper dependency.
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

/// The Notifier itself.
class MaintenanceNotifier extends Notifier<MaintenanceState> {
  late final DatabaseHelper _db;

  @override
  MaintenanceState build() {
    _db = ref.read(databaseHelperProvider);
    return const MaintenanceState();
  }

  Future<void> loadMaintenances() async {
    state = state.copyWith(isLoading: true);
    final maintenances = await _db.getMaintenances();
    state = state.copyWith(maintenances: maintenances, isLoading: false);
  }

  Future<void> loadChartData() async {
    final monthlyData = await _db.getMaintenancesPerMonth();
    final failureData = await _db.getFailureDistribution();
    state = state.copyWith(monthlyData: monthlyData, failureData: failureData);
  }

  Future<List<Maintenance>> getByMachine(int machineId) =>
      _db.getMaintenancesByMachine(machineId);

  Future<void> addMaintenance(Maintenance maintenance) async {
    await _db.insertMaintenance(maintenance);
    await loadMaintenances();
    await loadChartData();
  }

  Future<void> updateMaintenance(Maintenance maintenance) async {
    await _db.updateMaintenance(maintenance);
    await loadMaintenances();
    await loadChartData();
  }

  Future<void> deleteMaintenance(int id) async {
    await _db.deleteMaintenance(id);
    await loadMaintenances();
    await loadChartData();
  }
}

/// The provider to use in widgets.
final maintenanceProvider =
    NotifierProvider<MaintenanceNotifier, MaintenanceState>(() {
  return MaintenanceNotifier();
});