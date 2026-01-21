import 'package:amica/models/sdq_model.dart';
import 'package:amica/provider/sdq_provider.dart';
import 'package:amica/services/sdq_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';


@GenerateNiceMocks([MockSpec<SdqService>()])
import 'sdq_provider_test.mocks.dart';

void main() {
  late SdqProvider sdqProvider;
  late MockSdqService mockSdqService;

  final dummyHistoryItem = SdqHistoryItem(
    id: 1,
    date: '2023-01-01',
    totalScore: 10,
    interpretationTitle: 'Normal',
  );

  final dummyResult = SdqFullResult(
    scores: {'total': 10},
    interpretation: {'result': 'Normal'},
  );

  setUp(() {
    mockSdqService = MockSdqService();
    sdqProvider = SdqProvider(service: mockSdqService);
  });

  group('SdqProvider Unit Test', () {
    test('Initial state harus bersih', () {
      expect(sdqProvider.history, isEmpty);
      expect(sdqProvider.isLoading, false);
    });

    test('fetchHistory Success: harus mengisi list history', () async {
      when(mockSdqService.getHistory())
          .thenAnswer((_) async => [dummyHistoryItem]);

      await sdqProvider.fetchHistory();

      expect(sdqProvider.isLoading, false);
      expect(sdqProvider.history.length, 1);
      expect(sdqProvider.history.first.interpretationTitle, 'Normal');
    });

    test('fetchHistory Failed: harus menangani error dengan aman (list tetap kosong)', () async {
      when(mockSdqService.getHistory())
          .thenThrow(Exception('API Error'));

      await sdqProvider.fetchHistory();

      expect(sdqProvider.isLoading, false);
      expect(sdqProvider.history, isEmpty);
    });

    test('submitQuiz Success: harus mengembalikan hasil dan refresh history', () async {
      when(mockSdqService.submitAnswers(any)).thenAnswer((_) async => dummyResult);
      when(mockSdqService.getHistory()).thenAnswer((_) async => [dummyHistoryItem]);

      final result = await sdqProvider.submitQuiz([0, 1, 2]);

      expect(result, isNotNull);
      expect(result?.interpretation['result'], 'Normal');

      verify(mockSdqService.getHistory()).called(1);
    });

    test('submitQuiz Failed: harus return null', () async {
      when(mockSdqService.submitAnswers(any)).thenThrow(Exception('Gagal Submit'));

      final result = await sdqProvider.submitQuiz([0, 0, 0]);

      expect(result, null);
      expect(sdqProvider.isLoading, false);
    });
  });
}