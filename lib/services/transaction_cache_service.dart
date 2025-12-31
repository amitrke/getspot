import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

/// Cached transaction data with timestamp for TTL checking
class CachedTransaction {
  final String id;
  final String type;
  final num amount;
  final String description;
  final DateTime? createdAt;

  CachedTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    this.createdAt,
  });

  factory CachedTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CachedTransaction(
      id: doc.id,
      type: data['type'] ?? '',
      amount: data['amount'] ?? 0,
      description: data['description'] ?? 'No description',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// Cached transaction list with timestamp for TTL checking
class CachedTransactionList {
  final List<CachedTransaction> transactions;
  final DateTime timestamp;

  CachedTransactionList({
    required this.transactions,
    required this.timestamp,
  });
}

/// Singleton service for caching transaction history
///
/// Caches transaction lists per user per group with a 30-minute TTL.
/// Transactions are immutable once created, making them ideal for caching.
///
/// Usage:
/// ```dart
/// final transactionCache = TransactionCacheService();
/// final cachedTransactions = await transactionCache.getTransactions(groupId, userId);
/// if (cachedTransactions != null) {
///   for (var tx in cachedTransactions) {
///     print(tx.description);
///   }
/// }
/// ```
class TransactionCacheService {
  static final TransactionCacheService _instance =
      TransactionCacheService._internal();
  factory TransactionCacheService() => _instance;
  TransactionCacheService._internal();

  final Map<String, CachedTransactionList> _cache = {};
  // Using 30-minute TTL - transactions are immutable but new ones may be added
  final Duration _ttl = const Duration(minutes: 30);

  /// Generate cache key from groupId and userId
  String _getCacheKey(String groupId, String userId) => '$groupId:$userId';

  /// Get transaction list from cache or Firestore
  ///
  /// Returns cached data if available and fresh (within TTL).
  /// Otherwise, fetches from Firestore and updates the cache.
  Future<List<CachedTransaction>?> getTransactions(
    String groupId,
    String userId,
  ) async {
    final cacheKey = _getCacheKey(groupId, userId);

    // Check cache first
    if (_cache.containsKey(cacheKey)) {
      final cached = _cache[cacheKey]!;
      if (DateTime.now().difference(cached.timestamp) < _ttl) {
        developer.log(
          'Cache hit for transactions: $cacheKey',
          name: 'TransactionCacheService',
        );
        return cached.transactions;
      } else {
        developer.log(
          'Cache expired for transactions: $cacheKey',
          name: 'TransactionCacheService',
        );
      }
    }

    // Cache miss or expired - fetch from Firestore
    developer.log(
      'Cache miss for transactions: $cacheKey, fetching from Firestore',
      name: 'TransactionCacheService',
    );

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('groupId', isEqualTo: groupId)
          .where('uid', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      final transactions = snapshot.docs
          .map((doc) => CachedTransaction.fromFirestore(doc))
          .toList();

      _cache[cacheKey] = CachedTransactionList(
        transactions: transactions,
        timestamp: DateTime.now(),
      );

      developer.log(
        'Cached ${transactions.length} transactions for $cacheKey',
        name: 'TransactionCacheService',
      );

      return transactions;
    } catch (e) {
      developer.log(
        'Error fetching transactions for $cacheKey',
        name: 'TransactionCacheService',
        error: e,
      );
    }
    return null;
  }

  /// Invalidate cache for a specific user in a specific group
  ///
  /// Call this when a new transaction is created to force a fresh fetch
  /// on the next access.
  ///
  /// **When to call:**
  /// - After event registration (new debit transaction)
  /// - After event withdrawal (new credit transaction)
  /// - After manual wallet adjustment by admin
  void invalidate(String groupId, String userId) {
    final cacheKey = _getCacheKey(groupId, userId);
    _cache.remove(cacheKey);
    developer.log(
      'Cache invalidated for transactions: $cacheKey',
      name: 'TransactionCacheService',
    );
  }

  /// Invalidate all transactions for a specific group
  ///
  /// Useful when group-wide operations occur.
  void invalidateGroup(String groupId) {
    _cache.removeWhere((key, _) => key.startsWith('$groupId:'));
    developer.log(
      'Cache invalidated for all transactions in group: $groupId',
      name: 'TransactionCacheService',
    );
  }

  /// Clear all cached transaction data
  ///
  /// Useful for testing or when logging out.
  void clear() {
    _cache.clear();
    developer.log(
      'Transaction cache cleared',
      name: 'TransactionCacheService',
    );
  }

  /// Get current cache size (for debugging)
  int get cacheSize => _cache.length;
}
