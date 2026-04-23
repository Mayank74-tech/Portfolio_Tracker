import 'package:hive_flutter/hive_flutter.dart';

class CacheManager {
  static const String _boxName = 'cache_box';

  static Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
  }

  static Future<void> put(
    String key,
    Object? value, {
    Duration? ttl,
  }) async {
    final box = await _box;
    await box.put(key, {
      'value': value,
      'expires_at':
          ttl == null ? null : DateTime.now().add(ttl).millisecondsSinceEpoch,
    });
  }

  static Future<T?> get<T>(String key) async {
    final box = await _box;
    final entry = box.get(key);

    if (entry is! Map) return null;

    final expiresAt = entry['expires_at'];
    if (expiresAt is int && DateTime.now().millisecondsSinceEpoch > expiresAt) {
      await box.delete(key);
      return null;
    }

    final value = entry['value'];
    return value is T ? value : null;
  }

  static Future<bool> containsFresh(String key) async {
    return await get<Object>(key) != null;
  }

  static Future<void> remove(String key) async {
    final box = await _box;
    await box.delete(key);
  }

  static Future<void> clear() async {
    final box = await _box;
    await box.clear();
  }

  static Future<Box<dynamic>> get _box async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }
}
