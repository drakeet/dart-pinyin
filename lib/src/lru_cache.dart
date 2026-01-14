import 'dart:collection';

class LruCache<K, V> {
  final int capacity;
  final LinkedHashMap<K, V?> _map = LinkedHashMap();

  LruCache({required this.capacity}) {
    if (capacity <= 0) {
      throw ArgumentError('capacity must be > 0');
    }
  }

  bool containsKey(K key) => _map.containsKey(key);

  V? get(K key) {
    final hadKey = _map.containsKey(key);
    if (!hadKey) return null;
    final value = _map.remove(key);
    _map[key] = value;
    return value;
  }

  void put(K key, V? value) {
    if (_map.containsKey(key)) {
      _map.remove(key);
    } else if (_map.length >= capacity) {
      _map.remove(_map.keys.first);
    }
    _map[key] = value;
  }

  void clear() => _map.clear();
}
