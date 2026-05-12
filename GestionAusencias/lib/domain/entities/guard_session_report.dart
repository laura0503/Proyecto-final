
class GuardSessionReport {
  final int? id;
  final int sustitucionId;
  final List<String> completedTasks;
  final String generalComment;
  final String behaviorNotes;
  final DateTime createdAt;

  GuardSessionReport({
    this.id,
    required this.sustitucionId,
    this.completedTasks = const [],
    this.generalComment = '',
    this.behaviorNotes = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
