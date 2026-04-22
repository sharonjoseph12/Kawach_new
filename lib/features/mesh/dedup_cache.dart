import 'dart:async';
import 'dart:collection';

/// In-memory deduplication cache for BLE mesh messages.
/// - Auto-expires entries after 1 hour.
/// - Max 500 entries with LRU eviction.
class DedupCache {
  static const int _maxEntries = 500;
  static const Duration _ttl = Duration(hours: 1);

  // LinkedHashMap preserves insertion order → easy LRU eviction
  final LinkedHashMap<String, Timer> _entries =
      LinkedHashMap<String, Timer>();

  bool isSeen(String msgId) => _entries.containsKey(msgId);

  void markSeen(String msgId) {
    if (_entries.containsKey(msgId)) {
      // Refresh: move to end (most recently used)
      final existing = _entries.remove(msgId)!;
      existing.cancel();
      _entries[msgId] = _createTimer(msgId);
      return;
    }

    // Evict least-recently-used if at capacity
    if (_entries.length >= _maxEntries) {
      final lruKey = _entries.keys.first;
      _entries[lruKey]?.cancel();
      _entries.remove(lruKey);
    }

    _entries[msgId] = _createTimer(msgId);
  }

  Timer _createTimer(String msgId) {
    return Timer(_ttl, () {
      _entries[msgId]?.cancel();
      _entries.remove(msgId);
    });
  }

  void clear() {
    for (final timer in _entries.values) {
      timer.cancel();
    }
    _entries.clear();
  }

  int get size => _entries.length;
}
