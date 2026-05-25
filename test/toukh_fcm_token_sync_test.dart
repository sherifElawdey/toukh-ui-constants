import 'package:flutter_test/flutter_test.dart';
import 'package:toukh_ui/toukh_ui.dart';

void main() {
  group('ToukhFcmTokenSync.mergeFcmToken', () {
    test('adds token to empty list', () {
      expect(
        ToukhFcmTokenSync.mergeFcmToken([], 't1'),
        ['t1'],
      );
    });

    test('returns unchanged list when token already exists', () {
      const existing = ['t1', 't2'];
      expect(
        ToukhFcmTokenSync.mergeFcmToken(existing, 't2'),
        existing,
      );
    });

    test('drops oldest when exceeding maxFcmTokens', () {
      const existing = ['t1', 't2', 't3', 't4', 't5'];
      expect(
        ToukhFcmTokenSync.mergeFcmToken(existing, 't6'),
        ['t2', 't3', 't4', 't5', 't6'],
      );
    });

    test('filters empty strings from existing', () {
      expect(
        ToukhFcmTokenSync.mergeFcmToken(['', 't1', ''], 't2'),
        ['t1', 't2'],
      );
    });
  });
}
