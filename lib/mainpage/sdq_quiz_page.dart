import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/sdq_provider.dart';
import '../models/sdq_model.dart'; // Pastikan ini diimpor
import 'sdq_results_page.dart'; // Halaman hasil detail

class SdQuizPage extends StatefulWidget {
  const SdQuizPage({super.key});

  @override
  State<SdQuizPage> createState() => _SdQuizPageState();
}

class _SdQuizPageState extends State<SdQuizPage> {
  final PageController _pageController = PageController();
  final List<int?> _answers = List.filled(25, null);
  int _currentPage = 0;
  bool _isSubmitting = false;

  final List<String> _questions = [
    'Dapat memperdulikan perasaan orang lain',
    'Gelisah, terlalu aktif, tidak dapat diam untuk waktu lama',
    'Sering mengeluh sakit kepala, sakit perut atau sakit-sakit lainnya',
    'Kalau mempunyai mainan, kesenangan, atau pensil, bersedia berbagi',
    'Sering sulit mengendalikan kemarahan',
    'Cenderung menyendiri, lebih suka bermain seorang diri',
    'Umumnya bertingkah laku baik, biasanya melakukan apa yang disuruh',
    'Banyak kekhawatiran atau sering tampak khawatir',
    'Suka menolong jika seseorang terluka, kecewa atau merasa sakit',
    'Terus menerus bergerak dengan resah atau menggeliat-geliat',
    'Mempunyai satu atau lebih teman baik',
    'Sering berkelahi dengan anak-anak lain atau mengintimidasi mereka',
    'Sering merasa tidak bahagia, sedih atau menangis',
    'Pada umumnya disukai oleh anak-anak lain',
    'Mudah teralih perhatiannya, tidak dapat berkonsentrasi',
    'Gugup atau sulit berpisah dengan orang tua pada situasi baru',
    'Bersikap baik terhadap anak-anak yang lebih muda',
    'Sering berbohong atau berbuat curang',
    'Diganggu, dipermainkan, diintimidasi atau diancam oleh anak lain',
    'Sering menawarkan diri untuk membantu orang lain',
    'Sebelum melakukan sesuatu ia berpikir dahulu tentang akibatnya',
    'Mencuri dari rumah, sekolah atau tempat lain',
    'Lebih mudah berteman dengan orang dewasa daripada dengan anak-anak',
    'Banyak yang ditakuti, mudah menjadi takut',
    'Memiliki perhatian yang baik terhadap apapun, mampu menyelesaikan tugas',
  ];

  void _onAnswerSelected(int questionIndex, int answerValue) async {
    setState(() {
      _answers[questionIndex] = answerValue;
    });

    if (questionIndex < _questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      await _submitResult();
    }
  }

  Future<void> _submitResult() async {
    setState(() => _isSubmitting = true);

    final finalAnswers = _answers.map((e) => e ?? 0).toList();

    final result = await context.read<SdqProvider>().submitQuiz(finalAnswers);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (result != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => SdResultDetailPage(result: result)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal mengirim jawaban. Coba lagi.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSubmitting) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Kuis SDQ (${_currentPage + 1}/${_questions.length})'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: LinearProgressIndicator(
            value: (_currentPage + 1) / _questions.length,
          ),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _questions.length,
        onPageChanged: (p) => setState(() => _currentPage = p),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _questions[index],
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 40),
                _buildOption(index, 'Tidak Benar', 0),
                const SizedBox(height: 12),
                _buildOption(index, 'Agak Benar', 1),
                const SizedBox(height: 12),
                _buildOption(index, 'Benar', 2),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOption(int index, String text, int val) {
    bool selected = _answers[index] == val;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => _onAnswerSelected(index, val),
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? Theme.of(context).primaryColor : null,
          foregroundColor: selected ? Colors.white : null,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(text),
      ),
    );
  }
}
