import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:amica/provider/post_provider.dart';
import 'package:amica/services/post_service.dart';
import 'package:amica/services/user_service.dart';
import 'package:amica/services/authenticated_client.dart';
import 'package:amica/models/post_model.dart';
import 'package:amica/models/user_model.dart';

@GenerateNiceMocks([
  MockSpec<PostService>(),
  MockSpec<UserService>(),
  MockSpec<AuthenticatedClient>(),
])
import 'post_provider_test.mocks.dart';

void main() {
  late PostProvider postProvider;
  late MockPostService mockPostService;
  late MockUserService mockUserService;
  late MockAuthenticatedClient mockAuthClient;

  final dummyAuthor = User(
    id: 'u1',
    username: 'clover',
    displayName: 'Clover',
    email: 'c@c.com',
    role: 'user',
  );

  final dummyPost = Post(
    id: 'p1',
    author: dummyAuthor,
    caption: 'Lucky Post',
    timestamp: DateTime.now(),
    likesCount: 0,
    commentsCount: 0,
    tags: [],
    isLiked: false,
    isSaved: false,
  );

  setUp(() {
    mockPostService = MockPostService();
    mockUserService = MockUserService();
    mockAuthClient = MockAuthenticatedClient();

    postProvider = PostProvider(
      postService: mockPostService,
      userService: mockUserService,
      authClient: mockAuthClient,
    );
  });

  group('PostProvider Unit Tests', () {
    test('Initial State harus kosong dan tidak loading', () {
      expect(postProvider.posts, isEmpty);
      expect(postProvider.isLoading, false);
      expect(postProvider.errorMessage, null);
    });

    test('fetchPosts Success: harus mengisi list posts', () async {
      when(
        mockPostService.getPosts(page: 1, perPage: 10, filter: 'latest'),
      ).thenAnswer(
        (_) async => {
          'success': true,
          'posts': [dummyPost],
          'has_next': false,
        },
      );

      await postProvider.fetchPosts();

      expect(postProvider.isLoading, false);
      expect(postProvider.posts.length, 1);
      expect(postProvider.posts.first.caption, 'Lucky Post');
    });

    test('fetchPosts Failed: harus set errorMessage', () async {
      when(
        mockPostService.getPosts(
          page: anyNamed('page'),
          perPage: anyNamed('perPage'),
          filter: anyNamed('filter'),
        ),
      ).thenAnswer((_) async => {'success': false, 'message': 'Server Error'});

      await postProvider.fetchPosts();

      expect(postProvider.posts, isEmpty);
      expect(postProvider.errorMessage, 'Server Error');
    });

    test('toggleLike: harus update UI secara optimistic', () async {
      when(
        mockPostService.getPosts(page: 1, perPage: 10, filter: 'latest'),
      ).thenAnswer(
        (_) async => {
          'success': true,
          'posts': [dummyPost],
          'has_next': false,
        },
      );
      await postProvider.fetchPosts();

      when(mockPostService.likePost('p1')).thenAnswer((_) async => true);

      await postProvider.toggleLike('p1');

      expect(postProvider.posts.first.isLiked, true);
      expect(postProvider.posts.first.likesCount, 1);
    });

    test('toggleLike Failed: harus rollback jika API gagal', () async {
      when(
        mockPostService.getPosts(page: 1, perPage: 10, filter: 'latest'),
      ).thenAnswer(
        (_) async => {
          'success': true,
          'posts': [dummyPost],
          'has_next': false,
        },
      );
      await postProvider.fetchPosts();

      when(mockPostService.likePost('p1')).thenAnswer((_) async => false);

      await postProvider.toggleLike('p1');

      expect(postProvider.posts.first.isLiked, false);
      expect(postProvider.posts.first.likesCount, 0);
    });

    test('createPost Success: harus refresh post list', () async {
      when(
        mockPostService.createPost(caption: 'New', tags: [], imageFile: null),
      ).thenAnswer((_) async => {'success': true, 'message': 'Created'});

      when(
        mockPostService.getPosts(page: 1, perPage: 10, filter: 'latest'),
      ).thenAnswer(
        (_) async => {'success': true, 'posts': <Post>[], 'has_next': false},
      );

      final result = await postProvider.createPost(caption: 'New', tags: []);

      expect(result['success'], true);
      verify(
        mockPostService.getPosts(page: 1, perPage: 10, filter: 'latest'),
      ).called(1);
    });
  });
}
