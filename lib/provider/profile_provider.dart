import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../models/user_profile_model.dart';
import '../services/user_service.dart';
import '../services/post_service.dart';

class ProfileProvider with ChangeNotifier {
  late final UserService _userService;
  late final PostService _postService;

  bool _isLoadingProfile = true;
  bool _isLoadingPosts = false;
  String? _errorMessage;

  UserProfileData? _userProfile;
  List<Post> _imagePosts = [];
  List<Post> _textPosts = [];

  int _currentPage = 1;
  bool _hasMorePosts = true;
  String _targetUserId = '';

  List<Post> _savedPosts = [];
  bool _isLoadingSaved = false;
  bool _isSavedCollectionPrivate = false;
  bool _myPrivacySetting = false;

  bool get isLoadingProfile => _isLoadingProfile;
  bool get isLoadingPosts => _isLoadingPosts;
  String? get errorMessage => _errorMessage;
  UserProfileData? get userProfile => _userProfile;
  List<Post> get imagePosts => _imagePosts;
  List<Post> get textPosts => _textPosts;
  bool get hasMorePosts => _hasMorePosts;

  List<Post> get savedPosts => _savedPosts;
  bool get isLoadingSaved => _isLoadingSaved;
  bool get isSavedCollectionPrivate => _isSavedCollectionPrivate;
  bool get myPrivacySetting => _myPrivacySetting;

  ProfileProvider({UserService? userService, PostService? postService}) {
    _userService = userService ?? UserService();
    _postService = postService ?? PostService();
  }

  set errorMessage(String? msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  Future<void> loadFullProfile(String userId, {String? currentUserId}) async {
    _targetUserId = userId;
    _isLoadingProfile = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _userProfile = await _userService.getUserProfile(userId);

      if (_userProfile == null) {
        _errorMessage = "Profil pengguna tidak ditemukan.";
      } else {
        if (currentUserId != null &&
            currentUserId.isNotEmpty &&
            _userProfile!.id == currentUserId) {
          if (!_userProfile!.status.isMe) {
            _userProfile = UserProfileData(
              id: _userProfile!.id,
              username: _userProfile!.username,
              displayName: _userProfile!.displayName,
              bio: _userProfile!.bio,
              avatarUrl: _userProfile!.avatarUrl,
              bannerUrl: _userProfile!.bannerUrl,
              stats: _userProfile!.stats,
              status: UserStatus(
                isMe: true,
                isFollowing: false,
                isSavedPostsPublic: _userProfile!.status.isSavedPostsPublic,
              ),
            );
          }
        }

        if (_userProfile!.status.isMe) {
          _myPrivacySetting = _userProfile!.status.isSavedPostsPublic;
        }

        _currentPage = 1;
        _imagePosts = [];
        _textPosts = [];
        _hasMorePosts = true;

        await _fetchMorePosts();
      }
    } catch (e) {
      final errorStr = e.toString().toLowerCase();

      if (errorStr.contains('socketexception') ||
          errorStr.contains('connection refused') ||
          errorStr.contains('network is unreachable') ||
          errorStr.contains('clientexception')) {
        _errorMessage = "Tidak ada koneksi internet. Periksa jaringan Anda.";
      } else if (errorStr.contains('timeout')) {
        _errorMessage = "Waktu koneksi habis. Silakan coba lagi.";
      } else {
        _errorMessage = "Terjadi kesalahan sistem. ($e)";
      }

      debugPrint("Profile Error: $e");
    }

    _isLoadingProfile = false;
    notifyListeners();
  }

  Future<void> loadSavedPosts(String targetUserId) async {
    _isLoadingSaved = true;
    _isSavedCollectionPrivate = false;
    notifyListeners();

    try {
      final result = await _userService.getSavedPosts(targetUserId);

      if (result['success'] == true) {
        _savedPosts = result['posts'];
      } else if (result['is_private'] == true) {
        _isSavedCollectionPrivate = true;
        _savedPosts = [];
      } else {
        _savedPosts = [];
      }
    } catch (e) {
      debugPrint("Error loading saved posts: $e");
      _savedPosts = [];
    }

    _isLoadingSaved = false;
    notifyListeners();
  }

  Future<bool> togglePrivacySetting(bool value) async {
    _myPrivacySetting = value;
    notifyListeners();

    final success = await _userService.updateSavedPrivacy(value);

    if (!success) {
      _myPrivacySetting = !value;
      notifyListeners();
      return false;
    }
    return true;
  }

  void toggleLikeLocal(String postId) {
    _toggleLikeInList(_savedPosts, postId);
    _toggleLikeInList(_imagePosts, postId);
    _toggleLikeInList(_textPosts, postId);
    notifyListeners();
  }

  void _toggleLikeInList(List<Post> list, String postId) {
    final index = list.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final old = list[index];
      final newLiked = !old.isLiked;
      final newCount = newLiked
          ? old.likesCount + 1
          : (old.likesCount > 0 ? old.likesCount - 1 : 0);
      list[index] = old.copyWith(isLiked: newLiked, likesCount: newCount);
    }
  }

  void toggleSaveLocal(String postId) {
    _toggleSaveInList(_savedPosts, postId);
    _toggleSaveInList(_imagePosts, postId);
    _toggleSaveInList(_textPosts, postId);
    notifyListeners();
  }

  void _toggleSaveInList(List<Post> list, String postId) {
    final index = list.indexWhere((p) => p.id == postId);
    if (index != -1) {
      list[index] = list[index].copyWith(isSaved: !list[index].isSaved);
    }
  }

  Future<void> loadMorePosts() async {
    if (_isLoadingPosts || !_hasMorePosts || _targetUserId.isEmpty) return;
    await _fetchMorePosts();
  }

  Future<void> _fetchMorePosts() async {
    _isLoadingPosts = true;
    notifyListeners();

    try {
      final postResult = await _postService.getPosts(
        userId: _targetUserId,
        page: _currentPage,
        perPage: 12,
      );

      if (postResult['success']) {
        List<Post> newPosts = postResult['posts'];

        final newImages = newPosts
            .where((p) => p.fullImageUrl != null)
            .toList();
        final newTexts = newPosts.where((p) => p.fullImageUrl == null).toList();

        _imagePosts.addAll(newImages);
        _textPosts.addAll(newTexts);

        _hasMorePosts = postResult['has_next'] ?? false;
        if (_hasMorePosts) _currentPage++;
      }
    } catch (e) {
      debugPrint("Error loading posts: $e");
    }

    _isLoadingPosts = false;
    notifyListeners();
  }

  Future<void> refreshProfile({
    String? currentUserId,
    String? targetUserId,
  }) async {
    final String idToLoad = targetUserId ?? _targetUserId;

    if (_userProfile != null) {
      await loadFullProfile(_userProfile!.id, currentUserId: currentUserId);
      await loadSavedPosts(_userProfile!.id);
    } else if (idToLoad.isNotEmpty) {
      await loadFullProfile(idToLoad, currentUserId: currentUserId);
      await loadSavedPosts(idToLoad);
    } else {
      _errorMessage =
          "Gagal memuat ulang. ID tidak ditemukan. Coba tutup dan buka ulang aplikasi";
      notifyListeners();
    }
  }

  Future<void> toggleFollow() async {
    if (_userProfile == null) return;
    final oldStatus = _userProfile!.status.isFollowing;
    final oldFollowers = _userProfile!.stats.followers;

    _userProfile = UserProfileData(
      id: _userProfile!.id,
      username: _userProfile!.username,
      displayName: _userProfile!.displayName,
      bio: _userProfile!.bio,
      avatarUrl: _userProfile!.avatarUrl,
      bannerUrl: _userProfile!.bannerUrl,
      stats: UserStats(
        posts: _userProfile!.stats.posts,
        following: _userProfile!.stats.following,
        followers: oldStatus
            ? (oldFollowers > 0 ? oldFollowers - 1 : 0)
            : oldFollowers + 1,
      ),
      status: UserStatus(
        isMe: false,
        isFollowing: !oldStatus,
        isSavedPostsPublic: _userProfile!.status.isSavedPostsPublic,
      ),
    );
    notifyListeners();

    final success = await _userService.followUser(_userProfile!.id);
    if (!success) {
      final freshProfile = await _userService.getUserProfile(_userProfile!.id);
      if (freshProfile != null) {
        _userProfile = freshProfile;
        notifyListeners();
      }
    }
  }
}
