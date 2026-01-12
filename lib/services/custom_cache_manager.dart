import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class PostCacheManager {
  static const key = 'amicaPostCacheKey';
  static final CacheManager instance = CacheManager(
    Config(key,
      stalePeriod: const Duration(days: 3),
      maxNrOfCacheObjects: 30,
    ),
  );
}

class ProfileCacheManager {
  static const key = 'amicaProfileCacheKey';
  static final CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 30,
    ),
  );
}
