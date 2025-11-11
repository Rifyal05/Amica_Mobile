class Article {
  final String id;
  final String category;
  final String title;
  final String content;
  final String imageUrl;
  final int readTime;
  final List<String> tags;
  final String sourceName;
  final String sourceUrl;
  final bool isFeatured;

  const Article({
    required this.id,
    required this.category,
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.readTime,
    required this.tags,
    required this.sourceName,
    required this.sourceUrl,
    this.isFeatured = false,
  });

  static final List<Article> dummyArticles = [
    const Article(
      id: 'article_001',
      category: 'CYBERBULLYING',
      title: '5 Tanda Anak Anda Menjadi Korban Perundungan Siber',
      readTime: 5,
      imageUrl: 'https://images.pexels.com/photos/5699475/pexels-photo-5699475.jpeg?auto=compress&cs=tinysrgb&w=800',
      isFeatured: true,
      tags: ['cyberbullying', 'remaja', 'keamanan_digital'],
      sourceName: 'UNICEF',
      sourceUrl: 'https://www.unicef.org/end-violence/how-to-stop-cyberbullying',
      content: 'Memahami tanda-tanda perundungan siber bisa menjadi tantangan. Berikut adalah lima tanda kunci yang perlu diwaspadai oleh setiap orang tua.\n\n1. Perubahan Emosional yang Drastis\nAnak yang biasanya ceria menjadi mudah marah, cemas, atau sedih tanpa alasan yang jelas bisa menjadi pertanda. Perhatikan jika mereka menjadi lebih tertutup atau menarik diri dari aktivitas yang biasanya mereka nikmati.\n\n2. Penurunan Prestasi Akademik\nKesulitan berkonsentrasi di sekolah, nilai yang menurun, atau keengganan untuk pergi ke sekolah bisa menjadi tanda bahwa mereka sedang mengalami tekanan emosional akibat perundungan.',
    ),
    const Article(
      id: 'article_002',
      category: 'POLA ASUH',
      title: 'Membangun Komunikasi Terbuka dengan Anak Remaja Anda',
      readTime: 4,
      imageUrl: 'https://images.pexels.com/photos/7988086/pexels-photo-7988086.jpeg?auto=compress&cs=tinysrgb&w=800',
      tags: ['komunikasi', 'pola_asuh', 'remaja'],
      sourceName: 'Psychology Today',
      sourceUrl: 'https://www.psychologytoday.com/us/blog/surviving-your-childs-adolescence/201001/communicating-teenagers-connecting-vs-correcting',
      content: 'Membangun komunikasi yang kuat adalah fondasi hubungan yang sehat dengan remaja. Alih-alih selalu mengoreksi, cobalah untuk lebih banyak terhubung. Dengarkan cerita mereka tanpa menghakimi, dan validasi perasaan mereka meskipun Anda tidak setuju dengan perilakunya.',
    ),
  ];
}