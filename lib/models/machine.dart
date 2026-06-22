class Machine {
  final int? id;
  final String name;
  final String brand;
  final String model;
  final String serialNumber;
  final String installationDate;
  final String location;
  final String status;
  final String description;
  final String? lastMaintenanceDate;
  final int maintenanceFrequency;

  const Machine({
    this.id,
    required this.name,
    required this.brand,
    required this.model,
    required this.serialNumber,
    required this.installationDate,
    required this.location,
    required this.status,
    this.description = '',
    this.lastMaintenanceDate,
    this.maintenanceFrequency = 30,
  });

  factory Machine.fromMap(Map<String, dynamic> map) {
    return Machine(
      id: map['id'] as int?,
      name: map['name'] as String,
      brand: map['brand'] as String,
      model: map['model'] as String,
      serialNumber: map['serial_number'] as String,
      installationDate: map['installation_date'] as String,
      location: map['location'] as String,
      status: map['status'] as String,
      description: (map['description'] as String?) ?? '',
      lastMaintenanceDate: map['last_maintenance_date'] as String?,
      maintenanceFrequency: (map['maintenance_frequency'] as int?) ?? 30,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'brand': brand,
      'model': model,
      'serial_number': serialNumber,
      'installation_date': installationDate,
      'location': location,
      'status': status,
      'description': description,
      'last_maintenance_date': lastMaintenanceDate,
      'maintenance_frequency': maintenanceFrequency,
    };
  }

  Machine copyWith({
    int? id,
    String? name,
    String? brand,
    String? model,
    String? serialNumber,
    String? installationDate,
    String? location,
    String? status,
    String? description,
    String? lastMaintenanceDate,
    int? maintenanceFrequency,
  }) {
    return Machine(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      serialNumber: serialNumber ?? this.serialNumber,
      installationDate: installationDate ?? this.installationDate,
      location: location ?? this.location,
      status: status ?? this.status,
      description: description ?? this.description,
      lastMaintenanceDate: lastMaintenanceDate ?? this.lastMaintenanceDate,
      maintenanceFrequency: maintenanceFrequency ?? this.maintenanceFrequency,
    );
  }
}
