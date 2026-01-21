import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:amica/mainpage/sdq_quiz_page.dart';
import 'package:amica/provider/sdq_provider.dart';

@GenerateNiceMocks([
  MockSpec<SdqProvider>(),
  MockSpec<NavigatorObserver>(),
])
import 'sdq_quiz_page_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  late MockSdqProvider mockSdqProvider;
  late MockNavigatorObserver mockNavigatorObserver;

  setUp(() async {
    try {
      await Firebase.initializeApp(
        name: '[DEFAULT]',
        options: const FirebaseOptions(
          apiKey: 'fake',
          appId: 'fake',
          messagingSenderId: 'fake',
          projectId: 'fake',
        ),
      );
    } catch (_) {}

    mockSdqProvider = MockSdqProvider();
    mockNavigatorObserver = MockNavigatorObserver();
  });

  Widget createSdqQuizPage() {
    return ChangeNotifierProvider<SdqProvider>.value(
      value: mockSdqProvider,
      child: MaterialApp(
        home: const SdQuizPage(),
        navigatorObservers: [mockNavigatorObserver],
      ),
    );
  }

  group('SdQuizPage Widget Tests', () {
    testWidgets('Harus menampilkan pertanyaan pertama dan pilihan jawaban', (WidgetTester tester) async {
      await tester.pumpWidget(createSdqQuizPage());
      expect(find.textContaining('1/25'), findsOneWidget);
      expect(find.text('Dapat memperdulikan perasaan orang lain'), findsOneWidget);
      expect(find.text('Benar'), findsOneWidget);
    });

    testWidgets('Memilih jawaban harus mengubah warna tombol', (WidgetTester tester) async {
      await tester.pumpWidget(createSdqQuizPage());
      final optionButton = find.widgetWithText(OutlinedButton, 'Benar');
      await tester.tap(optionButton);
      await tester.pump();
      final OutlinedButton buttonWidget = tester.widget(optionButton);
      expect(buttonWidget.style?.backgroundColor != null, true);
    });

    testWidgets('Setelah memilih jawaban, harus berpindah ke pertanyaan berikutnya', (WidgetTester tester) async {
      await tester.pumpWidget(createSdqQuizPage());
      await tester.tap(find.text('Benar'));
      await tester.pumpAndSettle();
      expect(find.textContaining('2/25'), findsOneWidget);
    });

    testWidgets('Jika submitQuiz gagal (null), harus muncul SnackBar error', (WidgetTester tester) async {
      await tester.pumpWidget(createSdqQuizPage());

      when(mockSdqProvider.submitQuiz(any)).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return null;
      });

      for (int i = 0; i < 24; i++) {
        await tester.tap(find.text('Benar'));
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Benar'));

      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('Gagal mengirim jawaban. Coba lagi.'), findsOneWidget);
    });
  });
}