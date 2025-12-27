class SdqHistoryItem {
  final int id;
  final String date;
  final int totalScore;
  final String interpretationTitle;

  SdqHistoryItem({
    required this.id,
    required this.date,
    required this.totalScore,
    required this.interpretationTitle,
  });

  factory SdqHistoryItem.fromJson(Map<String, dynamic> json) {
    return SdqHistoryItem(
      id: json['id'],
      date: json['date'],
      totalScore: json['total_score'],
      interpretationTitle: json['interpretation_title'],
    );
  }
}

class SdqFullResult {
  final Map<String, dynamic> scores;
  final Map<String, dynamic> interpretation;

  SdqFullResult({required this.scores, required this.interpretation});

  factory SdqFullResult.fromJson(Map<String, dynamic> json) {
    return SdqFullResult(
      scores: json['scores'],
      interpretation: json['interpretation'],
    );
  }
}