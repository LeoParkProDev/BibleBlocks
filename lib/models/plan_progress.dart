/// 사용자가 현재 진행 중인 읽기 계획(영속화 대상).
class PlanProgress {
  final String planId;
  final DateTime startedAt;

  const PlanProgress({required this.planId, required this.startedAt});

  Map<String, dynamic> toJson() => {
        'planId': planId,
        'startedAt': startedAt.toIso8601String(),
      };

  factory PlanProgress.fromJson(Map<String, dynamic> json) => PlanProgress(
        planId: json['planId'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
      );

  @override
  bool operator ==(Object other) =>
      other is PlanProgress &&
      other.planId == planId &&
      other.startedAt == startedAt;

  @override
  int get hashCode => Object.hash(planId, startedAt);
}
