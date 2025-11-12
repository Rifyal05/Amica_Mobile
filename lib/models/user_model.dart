class User {
  final String id;
  final String username;
  final String displayName;
  final String avatarUrl;
  final String bannerUrl;
  final String bio;

  const User({
    required this.id,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
    required this.bannerUrl,
    required this.bio,
  });

  static final List<User> dummyUsers = [
    const User(
      id: 'user_001',
      username: 'bundahebat123',
      displayName: 'Bunda Hebat',
      avatarUrl: 'https://i.pravatar.cc/150?img=12',
      bannerUrl: 'https://images.pexels.com/photos/933054/pexels-photo-933054.jpeg?auto=compress&cs=tinysrgb&w=1260',
      bio: 'Menyebarkan positivitas dan saling mendukung. Di sini untuk mendengar dan membantu.',
    ),
    const User(
      id: 'user_002',
      username: 'ayahkeren',
      displayName: 'Ayah Keren',
      avatarUrl: 'https://i.pravatar.cc/150?img=32',
      bannerUrl: 'https://images.pexels.com/photos/374710/pexels-photo-374710.jpeg?auto=compress&cs=tinysrgb&w=1260',
      bio: 'Berbagi tips parenting modern dan cerita seru bersama anak-anak.',
    ),
    const User(
      id: 'user_003',
      username: 'pakarparenting',
      displayName: 'Dr. Amica, Sp.A',
      avatarUrl: 'https://i.pravatar.cc/150?img=31',
      bannerUrl: 'https://images.pexels.com/photos/1036808/pexels-photo-1036808.jpeg?auto=compress&cs=tinysrgb&w=1260',
      bio: 'Psikolog anak. Menyediakan sumber daya berbasis bukti untuk orang tua hebat.',
    ),
    const User(
      id: 'user_004',
      username: 'keluargaceri',
      displayName: 'Keluarga Ceria',
      avatarUrl: 'https://i.pravatar.cc/150?img=5',
      bannerUrl: 'https://images.pexels.com/photos/1683989/pexels-photo-1683989.jpeg?auto=compress&cs=tinysrgb&w=1260',
      bio: 'Menjelajahi dunia bersama, satu petualangan pada satu waktu.',
    ),
  ];
}