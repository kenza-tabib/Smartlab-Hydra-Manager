class AppConstants {
  static const String appName = 'Smart Lab Hydra Manager';
  static const String appVersion = '1.0.0';

  static const String roleAdmin = 'Administrateur';
  static const String roleTechnician = 'Technicien';

  static const String statusOperational = 'Fonctionnelle';
  static const String statusMaintenance = 'Maintenance';
  static const String statusOutOfService = 'Hors service';

  static const String maintenanceTypePreventive = 'Préventive';
  static const String maintenanceTypeCorrective = 'Corrective';

  static const List<int> maintenanceFrequencies = [30, 60, 90];
  static const int alertDaysBefore = 7;

  static const String prefLoggedIn = 'is_logged_in';
  static const String prefUserId = 'user_id';
  static const String prefUsername = 'username';
  static const String prefRole = 'role';
}
