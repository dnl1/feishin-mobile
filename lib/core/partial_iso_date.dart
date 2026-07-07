/// Port of feishin/src/shared/api/partial-iso-date.ts.
library;

final RegExp _partialIso = RegExp(r'^\d{4}(-\d{2}(-\d{2})?)?$');

typedef PartialIsoDate = ({String? date, int year});

int coerceYear(num? value) {
  if (value == null || !value.isFinite) {
    return 0;
  }

  return value.toInt();
}

/// Parses `YYYY`, `YYYY-MM`, or `YYYY-MM-DD`. Returns the trimmed string as
/// `date` when valid.
PartialIsoDate parsePartialIsoDate(String? input) {
  if (input == null) {
    return (date: null, year: 0);
  }

  final s = input.trim();
  if (s.isEmpty || !_partialIso.hasMatch(s)) {
    return (date: null, year: 0);
  }

  final year = int.tryParse(s.substring(0, 4));
  if (year == null) {
    return (date: null, year: 0);
  }

  return (date: s, year: year);
}

/// Like [parsePartialIsoDate], but if the value is a full ISO datetime, uses
/// the `YYYY-MM-DD` prefix.
PartialIsoDate parsePartialIsoDateFromApi(String? input) {
  final direct = parsePartialIsoDate(input);
  if (direct.date != null) {
    return direct;
  }

  if (input != null && input.length >= 10) {
    return parsePartialIsoDate(input.substring(0, 10));
  }

  return (date: null, year: 0);
}
