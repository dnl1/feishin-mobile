import 'package:feishin_mobile/core/partial_iso_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parsePartialIsoDate', () {
    test('parses YYYY, YYYY-MM and YYYY-MM-DD', () {
      expect(parsePartialIsoDate('2020'), (date: '2020', year: 2020));
      expect(parsePartialIsoDate('2020-03'), (date: '2020-03', year: 2020));
      expect(parsePartialIsoDate('2020-03-05'), (
        date: '2020-03-05',
        year: 2020,
      ));
    });

    test('trims whitespace', () {
      expect(parsePartialIsoDate(' 1999 '), (date: '1999', year: 1999));
    });

    test('rejects invalid input', () {
      expect(parsePartialIsoDate(null), (date: null, year: 0));
      expect(parsePartialIsoDate(''), (date: null, year: 0));
      expect(parsePartialIsoDate('banana'), (date: null, year: 0));
      expect(parsePartialIsoDate('2020-3-5'), (date: null, year: 0));
      expect(parsePartialIsoDate('2020-03-05T10:00:00Z'), (
        date: null,
        year: 0,
      ));
    });
  });

  group('parsePartialIsoDateFromApi', () {
    test('falls back to the YYYY-MM-DD prefix of a full ISO datetime', () {
      expect(parsePartialIsoDateFromApi('2020-03-05T10:00:00Z'), (
        date: '2020-03-05',
        year: 2020,
      ));
    });

    test('still rejects garbage', () {
      expect(parsePartialIsoDateFromApi('not-a-date-at-all'), (
        date: null,
        year: 0,
      ));
    });
  });

  group('coerceYear', () {
    test('passes finite numbers through and zeroes the rest', () {
      expect(coerceYear(1999), 1999);
      expect(coerceYear(null), 0);
      expect(coerceYear(double.nan), 0);
      expect(coerceYear(double.infinity), 0);
    });
  });
}
