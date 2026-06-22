import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../models/maintenance.dart';

class MaintenanceProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Maintenance> _maintenances = [];
  bool _isLoading = false;
  List<Map<String, dynamic>> _monthlyData = [];
  List<Map<String, dynamic>> _failureData = [];

  List<Maintenance> get maintenances => _maintenances;
  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get monthlyData => _monthlyData;
  List<Map<String, dynamic>> get failureData => _failureData;
  int get totalCount => _maintenances.length;

  Future<void> loadMaintenances() async {
    _isLoading = true;
    notifyListeners();
    _maintenances = await _db.getMaintenances();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadChartData() async {
    _monthlyData = await _db.getMaintenancesPerMonth();
    _failureData = await _db.getFailureDistribution();
    notifyListeners();
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
