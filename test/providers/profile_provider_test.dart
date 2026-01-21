import 'package:amica/models/post_model.dart';
import 'package:amica/models/user_profile_model.dart';
import 'package:amica/provider/profile_provider.dart';
import 'package:amica/services/post_service.dart';
import 'package:amica/services/user_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';


@GenerateNiceMocks([MockSpec<UserService>(), MockSpec<PostService>()])
import 'profile_provider_test.mocks.dart';

void main() {
  late ProfileProvider profileProvider;
  late MockUserService mockUserService;
  late MockPostService mockPostService;

  final dummyProfile = UserProfileData(
    id: 'u1',
    username: 'testuser',
    displayName: 'Test User',
    bio: 'Bio',
    status: UserStatus(isMe: false, isFollowing: false, isSavedPostsPublic: true),
    stats: UserStats(posts: 0, followers: 10, following: 5),
  );

  setUp(() {
    mockUserService = MockUserService();
    mockPostService = MockPostService();
    profileProvider = ProfileProvider(
      userService: mockUserService,
      postService: mockPostService,
    );
  });

  group('ProfileProvider Test', () {
    test('loadFullProfile Success: fills userProfile and fetches posts', () async {
      when(mockUserService.getUserProfile('u1'))
          .thenAnswer((_) async => dummyProfile);

      when(mockPostService.getPosts(userId: 'u1', page: 1, perPage: 12))
          .thenAnswer((_) async => {'success': true, 'posts': <Post>[], 'has_next': false});

      await profileProvider.loadFullProfile('u1');

      expect(profileProvider.isLoadingProfile, false);
      expect(profileProvider.userProfile?.username, 'testuser');
      expect(profileProvider.errorMessage, null);
      verify(mockPostService.getPosts(userId: 'u1', page: 1, perPage: 12)).called(1);
    });

    test('loadFullProfile Failed: sets errorMessage', () async {
      when(mockUserService.getUserProfile('invalid'))
          .thenAnswer((_) async => null);

      await profileProvider.loadFullProfile('invalid');

      expect(profileProvider.userProfile, null);
      expect(profileProvider.errorMessage, 'Profil pengguna tidak ditemukan.');
    });

    test('toggleFollow: updates UI immediately (Optimistic)', () async {
      when(mockUserService.getUserProfile('u1'))
          .thenAnswer((_) async => dummyProfile);
      when(mockPostService.getPosts(userId: 'u1', page: 1, perPage: 12))
          .thenAnswer((_) async => {'success': true, 'posts': <Post>[], 'has_next': false});

      await profileProvider.loadFullProfile('u1');

      when(mockUserService.followUser('u1')).thenAnswer((_) async => true);

      await profileProvider.toggleFollow();

      expect(profileProvider.userProfile?.status.isFollowing, true);
      expect(profileProvider.userProfile?.stats.followers, 11);
    });

    test('togglePrivacySetting: updates state and calls API', () async {
      when(mockUserService.updateSavedPrivacy(true)).thenAnswer((_) async => true);

      final result = await profileProvider.togglePrivacySetting(true);

      expect(result, true);
      expect(profileProvider.myPrivacySetting, true);
      verify(mockUserService.updateSavedPrivacy(true)).called(1);
    });
  });
}