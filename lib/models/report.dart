class Report {
  final String machineName;
  final String date;
  final String technician;
  final String failureDescription;
  final String intervention;
  final String result;

  const Report({
    required this.machineName,
    required this.date,
    required this.technician,
    required this.failureDescription,
    required this.intervention,
    required this.result,
  });
}
