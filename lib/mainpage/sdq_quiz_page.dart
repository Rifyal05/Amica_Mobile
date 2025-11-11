import 'package:flutter/material.dart';
import 'sdq_results_page.dart';

class SdQuizPage extends StatefulWidget {
  const SdQuizPage({super.key});

  @override
  State<SdQuizPage> createState() => _SdQuizPageState();
}

class _SdQuizPageState extends State<SdQuizPage> {
  final PageController _pageController = PageController();
  final List<int?> _answers = List.filled(25, null);
  int _currentPage = 0;

  final List<String> _questions = [
    'Dapat memperdulikan perasaan orang lain',
    'Gelisah, terlalu aktif, tidak dapat diam untuk waktu lama',
    'Sering mengeluh sakit kepala, sakit perut atau sakit-sakit lainnya',
    'Kalau mempunyai mainan, kesenangan, atau pensil, bersedia berbagi dengan anak-anak lain',
    'Sering sulit mengendalikan kemarahan',
    'Cenderung menyendiri, lebih suka bermain seorang diri',
    'Umumnya bertingkah laku baik, biasanya melakukan apa yang disuruh oleh orang dewasa',
    'Banyak kekhawatiran atau sering tampak khawatir',
    'Suka menolong jika seseorang terluka, kecewa atau merasa sakit',
    'Terus menerus bergerak dengan resah atau menggeliat-geliat',
    'Mempunyai satu atau lebih teman baik',
    'Sering berkelahi dengan anak-anak lain atau mengintimidasi mereka',
    'Sering merasa tidak bahagia, sedih atau menangis',
    'Pada umumnya disukai oleh anak-anak lain',
    'Mudah teralih perhatiannya, tidak dapat berkonsentrasi',
    'Gugup atau sulit berpisah dengan orang tua/pengasuhnya pada situasi baru, mudah kehilangan rasa percaya diri',
    'Bersikap baik terhadap anak-anak yang lebih muda',
    'Sering berbohong atau berbuat curang',
    'Diganggu, dipermainkan, diintimidasi atau diancam oleh anak-anak lain',
    'Sering menawarkan diri untuk membantu orang lain (orang tua, guru, anak-anak lain)',
    'Sebelum melakukan sesuatu ia berpikir dahulu tentang akibatnya',
    'Mencuri dari rumah, sekolah atau tempat lain',
    'Lebih mudah berteman dengan orang dewasa daripada dengan anak-anak lain',
    'Banyak yang ditakuti, mudah menjadi takut',
    'Memiliki perhatian yang baik terhadap apapun, mampu menyelesaikan tugas atau pekerjaan rumah sampai selesai'
  ];

  /*
  =============================================================================
  ANALISIS WHITE-BOX TESTING: FUNGSI _onAnswerSelected
  -----------------------------------------------------------------------------
  Teknik: Branch Coverage
  Tujuan: Memvalidasi alur navigasi setelah pengguna menjawab pertanyaan,
          memastikan semua jalur logika dieksekusi.

  Kode ini memiliki dua cabang keputusan yang jelas dan saling eksklusif:
  1. [Branch 1]: Pengecekan 'if (questionIndex < _questions.length - 1)'.
                 Jalur ini dieksekusi jika kuis BELUM selesai (pertanyaan 1-24).
  2. [Branch 2]: Jalur 'else'.
                 Jalur ini dieksekusi jika kuis TELAH selesai (setelah menjawab
                 pertanyaan 25, di mana questionIndex = 24).

  Kasus Uji untuk Mencapai 100% Branch Coverage:
  1. Aksi: Jawab pertanyaan nomor 5 (atau nomor apa pun < 25).
     -> Hasil: Mengeksekusi Branch 1. Memanggil `_pageController.nextPage()` dan
              aplikasi berpindah ke pertanyaan berikutnya.
  2. Aksi: Jawab pertanyaan terakhir (nomor 25).
     -> Hasil: Mengeksekusi Branch 2. Memanggil `Navigator.pushReplacement()` dan
              aplikasi berpindah ke halaman `SdResultsPage`.
  =============================================================================
  */
  void _onAnswerSelected(int questionIndex, int answerValue) {
    setState(() {
      _answers[questionIndex] = answerValue;
    });

    // [Branch 1]: Kuis belum selesai.
    if (questionIndex < _questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
    // [Branch 2]: Kuis telah selesai.
    else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => SdResultsPage(answers: _answers),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
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
        onPageChanged: (page) {
          setState(() {
            _currentPage = page;
          });
        },
        itemBuilder: (context, index) {
          return _buildQuestionCard(
            questionIndex: index,
            questionText: _questions[index],
          );
        },
      ),
    );
  }

  Widget _buildQuestionCard({required int questionIndex, required String questionText}) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            questionText,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 40),
          _buildAnswerOption(questionIndex, 'Tidak Benar', 0),
          const SizedBox(height: 12),
          _buildAnswerOption(questionIndex, 'Agak Benar', 1),
          const SizedBox(height: 12),
          _buildAnswerOption(questionIndex, 'Benar', 2),
        ],
      ),
    );
  }

  Widget _buildAnswerOption(int questionIndex, String text, int value) {
    final bool isSelected = _answers[questionIndex] == value;
    return ChoiceChip(
      label: Text(text),
      selected: isSelected,
      onSelected: (_) => _onAnswerSelected(questionIndex, value),
      labelStyle: TextStyle(
        fontSize: 16,
        color: isSelected
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSurface,
      ),
      selectedColor: Theme.of(context).colorScheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: const StadiumBorder(),
    );
  }
}