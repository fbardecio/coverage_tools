// secure_storage_hive.dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:storage/storage.dart';

/// {@template secure_storage}
/// A Dart Storage Client Implementation
/// This class is a secure storage implementation using Hive.
/// It implements the [Storage] interface.
/// {@endtemplate}
class SecureStorage implements Storage {
  /// {@macro secure_storage}
  SecureStorage({Box<String>? box}) : _box = box;

  late Box<String>? _box;

  /// Initializes the storage implementation.
  /// This method initializes the storage implementation by opening a Hive box
  /// with the provided [boxName].
  Future<void> init({required String boxName}) async {
    await Hive.initFlutter();
    _box = await Hive.openBox<String>(boxName);
  }

  /// Returns value for the provided [key].
  @override
  Future<String?> read({required String key}) async {
    try {
      return _box?.get(key);
    } catch (e) {
      throw StorageException('Failed to read from Hive: $e');
    }
  }

  // Writes the provided [key], [value] pair asynchronously.
  @override
  Future<void> write({required String key, required String value}) async {
    try {
      await _box?.put(key, value);
    } catch (e) {
      throw StorageException('Failed to write to Hive: $e');
    }
  }

  // Removes the value for the provided [key] asynchronously.
  @override
  Future<void> delete({required String key}) async {
    try {
      await _box?.delete(key);
    } catch (e) {
      throw StorageException('Failed to delete from Hive: $e');
    }
  }

  /// Removes all key, value pairs asynchronously.
  @override
  Future<void> clear() async {
    try {
      await _box?.clear();
    } catch (e) {
      throw StorageException('Failed to clear Hive box: $e');
    }
  }

  /// Closes the storage implementation.
  ///
  /// This method closes the storage implementation by closing the underlying
  ///  box.
  /// It is an asynchronous operation that returns a [Future] that completes
  /// when the box is closed.
  Future<void> close() async {
    await _box?.close();
  }
}
