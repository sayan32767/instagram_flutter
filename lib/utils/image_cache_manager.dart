import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class InstaCacheManager extends CacheManager {
  static const key = "instaCache";

  static final InstaCacheManager _instance = InstaCacheManager._();

  factory InstaCacheManager() => _instance;

  InstaCacheManager._()
      : super(
          Config(
            key,
            stalePeriod: const Duration(days: 7), // ⭐ keep 30 days
            maxNrOfCacheObjects: 500, // ⭐ large cache
          ),
        );
}
