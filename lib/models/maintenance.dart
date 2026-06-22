class Maintenance {
  final int? id;
  final int machineId;
  final String date;
  final String type;
  final String failure;
  final String solution;
  final String technician;
  final String? nextMaintenance;

  const Maintenance({
    this.id,
    required this.machineId,
    required this.date,
    required this.type,
    this.failure = '',
    required this.solution,
    required this.technician,
    this.nextMaintenance,
  });

  factory Maintenance.fromMap(Map<String, dynamic> map) {
    return Maintenance(
      id: map['id'] as int?,
      machineId: map['machine_id'] as int,
      date: map['date'] as String,
      type: map['type'] as String,
      failure: (map['failure'] as String?) ?? '',
      solution: map['solution'] as String,
      technician: map['technician'] as String,
      nextMaintenance: map['next_maintenance'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'machine_id': machineId,
      'date': date,
      'type': type,
      'failure': failure,
      'solution': solution,
      'technician': technician,
      'next_maintenance': nextMaintenance,
    };
  }

  Maintenance copyWith({
    int? id,
    int? machineId,
    String? date,
    String? type,
    String? failure,
    String? solution,
    String? technician,
    String? nextMaintenance,
  }) {
    return Maintenance(
      id: id ?? this.id,
      machineId: machineId ?? this.machineId,
      date: date ?? this.date,
      type: type ?? this.type,
      failure: failure ?? this.failure,
      solution: solution ?? this.solution,
      technician: technician ?? this.technician,
      nextMaintenance: nextMaintenance ?? this.nextMaintenance,
    );
  }
}
