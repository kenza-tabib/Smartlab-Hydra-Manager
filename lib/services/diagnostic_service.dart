import '../database/database_helper.dart';
import '../models/diagnostic.dart';

class DiagnosticService {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<List<String>> getCategories() => _db.getDiagnosticCategories();

  Future<List<String>> getSymptoms(String category) =>
      _db.getSymptomsByCategory(category);

  Future<List<Diagnostic>> diagnose(String symptom) =>
      _db.getDiagnosticsBySymptom(symptom);
}
