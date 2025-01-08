/// {@template storage_exception}
/// Exception thrown if a storage operation fails.
/// {@endtemplate}
class StorageException implements Exception {
  /// {@macro storage_exception}
  const StorageException(this.error);

  /// Error thrown during the storage operation.
  final Object error;
}
