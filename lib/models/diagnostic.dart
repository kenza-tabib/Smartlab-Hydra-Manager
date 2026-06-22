class Diagnostic {
  final int? id;
  final String symptom;
  final String category;
  final String possibleCause;
  final String recommendedAction;

  const Diagnostic({
    this.id,
    required this.symptom,
    required this.category,
    required this.possibleCause,
    required this.recommendedAction,
  });

  factory Diagnostic.fromMap(Map<String, dynamic> map) {
    return Diagnostic(
      id: map['id'] as int?,
      symptom: map['symptom'] as String,
      category: (map['category'] as String?) ?? '',
      possibleCause: map['possible_cause'] as String,
      recommendedAction: map['recommended_action'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'symptom': symptom,
      'category': category,
      'possible_cause': possibleCause,
      'recommended_action': recommendedAction,
    };
  }
}
