import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../core/constants/app_constants.dart';
import '../models/diagnostic.dart';
import '../models/machine.dart';
import '../models/maintenance.dart';
import '../models/user.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'smart_lab_hydra.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        role TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE machines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        brand TEXT NOT NULL,
        model TEXT NOT NULL,
        serial_number TEXT NOT NULL,
        installation_date TEXT NOT NULL,
        location TEXT NOT NULL,
        status TEXT NOT NULL,
        description TEXT,
        last_maintenance_date TEXT,
        maintenance_frequency INTEGER DEFAULT 30
      )
    ''');

    await db.execute('''
      CREATE TABLE maintenances (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        machine_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        failure TEXT,
        solution TEXT NOT NULL,
        technician TEXT NOT NULL,
        next_maintenance TEXT,
        FOREIGN KEY (machine_id) REFERENCES machines (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE diagnostics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        symptom TEXT NOT NULL,
        category TEXT,
        possible_cause TEXT NOT NULL,
        recommended_action TEXT NOT NULL
      )
    ''');

    await _seedData(db);
  }

  Future<void> _seedData(Database db) async {
    await db.insert('users', {
      'username': 'admin',
      'password': 'admin123',
      'role': AppConstants.roleAdmin,
    });
    await db.insert('users', {
      'username': 'tech',
      'password': 'tech123',
      'role': AppConstants.roleTechnician,
    });

    final now = DateTime.now();
    final machines = [
      {
        'name': 'HydraFacial Elite #1',
        'brand': 'HydraFacial',
        'model': 'Elite',
        'serial_number': 'HF-EL-2024-001',
        'installation_date': '2024-01-15',
        'location': 'Cabinet 1',
        'status': AppConstants.statusOperational,
        'description': 'Machine principale du cabinet esthétique',
        'last_maintenance_date': now.subtract(const Duration(days: 25)).toIso8601String().split('T')[0],
        'maintenance_frequency': 30,
      },
      {
        'name': 'HydraFacial Syndeo #2',
        'brand': 'HydraFacial',
        'model': 'Syndeo',
        'serial_number': 'HF-SY-2024-002',
        'installation_date': '2024-03-20',
        'location': 'Cabinet 2',
        'status': AppConstants.statusOperational,
        'description': 'Machine Syndeo avec boosters',
        'last_maintenance_date': now.subtract(const Duration(days: 55)).toIso8601String().split('T')[0],
        'maintenance_frequency': 60,
      },
      {
        'name': 'HydraFacial MD #3',
        'brand': 'HydraFacial',
        'model': 'MD',
        'serial_number': 'HF-MD-2023-003',
        'installation_date': '2023-06-10',
        'location': 'Salle VIP',
        'status': AppConstants.statusMaintenance,
        'description': 'En maintenance préventive',
        'last_maintenance_date': now.subtract(const Duration(days: 88)).toIso8601String().split('T')[0],
        'maintenance_frequency': 90,
      },
    ];

    for (final machine in machines) {
      await db.insert('machines', machine);
    }

    final maintenances = [
      {
        'machine_id': 1,
        'date': now.subtract(const Duration(days: 25)).toIso8601String().split('T')[0],
        'type': AppConstants.maintenanceTypePreventive,
        'failure': '',
        'solution': 'Remplacement filtres, nettoyage circuit',
        'technician': 'tech',
        'next_maintenance': now.add(const Duration(days: 5)).toIso8601String().split('T')[0],
      },
      {
        'machine_id': 2,
        'date': now.subtract(const Duration(days: 10)).toIso8601String().split('T')[0],
        'type': AppConstants.maintenanceTypeCorrective,
        'failure': 'Faible aspiration',
        'solution': 'Nettoyage filtre et vérification pompe',
        'technician': 'tech',
        'next_maintenance': null,
      },
      {
        'machine_id': 3,
        'date': now.subtract(const Duration(days: 5)).toIso8601String().split('T')[0],
        'type': AppConstants.maintenanceTypePreventive,
        'failure': '',
        'solution': 'Maintenance complète en cours',
        'technician': 'admin',
        'next_maintenance': now.add(const Duration(days: 85)).toIso8601String().split('T')[0],
      },
    ];

    for (final maintenance in maintenances) {
      await db.insert('maintenances', maintenance);
    }

    final diagnostics = [
      // Vacuum
      {'symptom': 'Faible aspiration', 'category': 'Vacuum', 'possible_cause': 'Filtre obstrué', 'recommended_action': 'Nettoyer ou remplacer le filtre'},
      {'symptom': 'Faible aspiration', 'category': 'Vacuum', 'possible_cause': 'Pompe usée', 'recommended_action': 'Vérifier et remplacer la pompe si nécessaire'},
      {'symptom': 'Faible aspiration', 'category': 'Vacuum', 'possible_cause': 'Fuite tuyauterie', 'recommended_action': 'Contrôler les raccordements et joints'},
      {'symptom': 'Absence aspiration', 'category': 'Vacuum', 'possible_cause': 'Pompe défaillante', 'recommended_action': 'Tester la pompe et remplacer si hors service'},
      {'symptom': 'Absence aspiration', 'category': 'Vacuum', 'possible_cause': 'Tuyau déconnecté', 'recommended_action': 'Vérifier toutes les connexions du circuit vacuum'},
      {'symptom': 'Bruit anormal', 'category': 'Vacuum', 'possible_cause': 'Roulement pompe usé', 'recommended_action': 'Inspecter et lubrifier ou remplacer la pompe'},
      {'symptom': 'Bruit anormal', 'category': 'Vacuum', 'possible_cause': 'Corps étranger dans le circuit', 'recommended_action': 'Nettoyer le circuit d\'aspiration'},
      // Radiofréquence
      {'symptom': 'Chauffe insuffisante', 'category': 'Radiofréquence', 'possible_cause': 'Électrode usée', 'recommended_action': 'Remplacer l\'électrode RF'},
      {'symptom': 'Chauffe insuffisante', 'category': 'Radiofréquence', 'possible_cause': 'Paramètres incorrects', 'recommended_action': 'Recalibrer les paramètres RF'},
      {'symptom': 'Absence énergie', 'category': 'Radiofréquence', 'possible_cause': 'Câble RF défectueux', 'recommended_action': 'Vérifier et remplacer le câble RF'},
      {'symptom': 'Absence énergie', 'category': 'Radiofréquence', 'possible_cause': 'Générateur RF en panne', 'recommended_action': 'Diagnostiquer le module générateur'},
      // Ultrasons
      {'symptom': 'Vibration faible', 'category': 'Ultrasons', 'possible_cause': 'Tête ultrason usée', 'recommended_action': 'Remplacer la tête ultrason'},
      {'symptom': 'Vibration faible', 'category': 'Ultrasons', 'possible_cause': 'Gel insuffisant', 'recommended_action': 'Appliquer une couche de gel conducteur'},
      {'symptom': 'Pas de vibration', 'category': 'Ultrasons', 'possible_cause': 'Connexion tête défectueuse', 'recommended_action': 'Vérifier le connecteur de la tête'},
      {'symptom': 'Pas de vibration', 'category': 'Ultrasons', 'possible_cause': 'Module ultrason HS', 'recommended_action': 'Tester et remplacer le module'},
      // Hydrodermabrasion
      {'symptom': 'Débit faible', 'category': 'Hydrodermabrasion', 'possible_cause': 'Buse obstruée', 'recommended_action': 'Nettoyer ou remplacer la buse'},
      {'symptom': 'Débit faible', 'category': 'Hydrodermabrasion', 'possible_cause': 'Réservoir bas', 'recommended_action': 'Remplir le réservoir de solution'},
      {'symptom': 'Fuite liquide', 'category': 'Hydrodermabrasion', 'possible_cause': 'Joint usé', 'recommended_action': 'Remplacer les joints du circuit liquide'},
      {'symptom': 'Fuite liquide', 'category': 'Hydrodermabrasion', 'possible_cause': 'Raccord desserré', 'recommended_action': 'Serrer les raccords et vérifier l\'étanchéité'},
    ];

    for (final diagnostic in diagnostics) {
      await db.insert('diagnostics', diagnostic);
    }
  }

  // Users
  Future<User?> getUserByCredentials(String username, String password) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  // Machines
  Future<List<Machine>> getMachines() async {
    final db = await database;
    final maps = await db.query('machines', orderBy: 'name ASC');
    return maps.map(Machine.fromMap).toList();
  }

  Future<Machine?> getMachine(int id) async {
    final db = await database;
    final maps = await db.query('machines', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Machine.fromMap(maps.first);
  }

  Future<int> insertMachine(Machine machine) async {
    final db = await database;
    return db.insert('machines', machine.toMap());
  }

  Future<int> updateMachine(Machine machine) async {
    final db = await database;
    return db.update(
      'machines',
      machine.toMap(),
      where: 'id = ?',
      whereArgs: [machine.id],
    );
  }

  Future<int> deleteMachine(int id) async {
    final db = await database;
    await db.delete('maintenances', where: 'machine_id = ?', whereArgs: [id]);
    return db.delete('machines', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> countMachinesByStatus(String status) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM machines WHERE status = ?',
      [status],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> countAllMachines() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM machines');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Maintenances
  Future<List<Maintenance>> getMaintenances() async {
    final db = await database;
    final maps = await db.query('maintenances', orderBy: 'date DESC');
    return maps.map(Maintenance.fromMap).toList();
  }

  Future<List<Maintenance>> getMaintenancesByMachine(int machineId) async {
    final db = await database;
    final maps = await db.query(
      'maintenances',
      where: 'machine_id = ?',
      whereArgs: [machineId],
      orderBy: 'date DESC',
    );
    return maps.map(Maintenance.fromMap).toList();
  }

  Future<int> insertMaintenance(Maintenance maintenance) async {
    final db = await database;
    return db.insert('maintenances', maintenance.toMap());
  }

  Future<int> updateMaintenance(Maintenance maintenance) async {
    final db = await database;
    return db.update(
      'maintenances',
      maintenance.toMap(),
      where: 'id = ?',
      whereArgs: [maintenance.id],
    );
  }

  Future<int> deleteMaintenance(int id) async {
    final db = await database;
    return db.delete('maintenances', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> countAllMaintenances() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM maintenances');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getMaintenancesPerMonth() async {
    final db = await database;
    return db.rawQuery('''
      SELECT strftime('%Y-%m', date) as month, COUNT(*) as count
      FROM maintenances
      GROUP BY strftime('%Y-%m', date)
      ORDER BY month ASC
      LIMIT 12
    ''');
  }

  Future<List<Map<String, dynamic>>> getFailureDistribution() async {
    final db = await database;
    return db.rawQuery('''
      SELECT failure, COUNT(*) as count
      FROM maintenances
      WHERE failure IS NOT NULL AND failure != ''
      GROUP BY failure
      ORDER BY count DESC
      LIMIT 6
    ''');
  }

  // Diagnostics
  Future<List<String>> getDiagnosticCategories() async {
    final db = await database;
    final maps = await db.rawQuery(
      'SELECT DISTINCT category FROM diagnostics WHERE category IS NOT NULL ORDER BY category',
    );
    return maps.map((m) => m['category'] as String).toList();
  }

  Future<List<String>> getSymptomsByCategory(String category) async {
    final db = await database;
    final maps = await db.rawQuery(
      'SELECT DISTINCT symptom FROM diagnostics WHERE category = ? ORDER BY symptom',
      [category],
    );
    return maps.map((m) => m['symptom'] as String).toList();
  }

  Future<List<Diagnostic>> getDiagnosticsBySymptom(String symptom) async {
    final db = await database;
    final maps = await db.query(
      'diagnostics',
      where: 'symptom = ?',
      whereArgs: [symptom],
    );
    return maps.map(Diagnostic.fromMap).toList();
  }
}
