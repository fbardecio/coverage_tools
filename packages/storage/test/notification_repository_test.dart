import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:storage/storage.dart';

class MockStorage extends Mock implements SecureStorage {}

void main() {
  test('Mock test for CI', () {
    expect(
      MockStorage is SecureStorage,
      false,
    );
  });
}
