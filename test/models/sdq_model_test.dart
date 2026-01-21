import 'package:amica/models/sdq_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SDQ Models Unit Test', () {

    test('SdqHistoryItem.fromJson harus mem-parsing data lengkap dengan benar', () {
      final Map<String, dynamic> json = {
        'id': 101,
        'date': '2023-10-27',
        'total_score': 25,
        'interpretation_title': 'Abnormal (High Need)',
      };

      final item = SdqHistoryItem.fromJson(json);

      expect(item.id, 101);
      expect(item.date, '2023-10-27');
      expect(item.totalScore, 25);
      expect(item.interpretationTitle, 'Abnormal (High Need)');
    });

    test('SdqFullResult.fromJson harus mem-parsing scores dan interpretation yang valid', () {
      final Map<String, dynamic> json = {
        'scores': {
          'emotional_problems': 5,
          'conduct_problems': 3,
          'total_difficulty': 15
        },
        'interpretation': {
          'result': 'Borderline',
          'description': 'Perlu pemantauan.'
        }
      };

      final result = SdqFullResult.fromJson(json);

      expect(result.scores['emotional_problems'], 5);
      expect(result.scores['total_difficulty'], 15);
      expect(result.interpretation['result'], 'Borderline');
    });

    test('SdqFullResult.fromJson harus menangani NULL dengan aman (Fallback to empty Map)', () {
      final Map<String, dynamic> jsonWithNulls = {
        'scores': null,
        'interpretation': null,
      };

      final Map<String, dynamic> jsonEmpty = {};

      final resultNull = SdqFullResult.fromJson(jsonWithNulls);
      expect(resultNull.scores, isA<Map>());
      expect(resultNull.scores, isEmpty);
      expect(resultNull.interpretation, isEmpty);

      final resultEmpty = SdqFullResult.fromJson(jsonEmpty);
      expect(resultEmpty.scores, isEmpty);
      expect(resultEmpty.interpretation, isEmpty);
    });
  });
}