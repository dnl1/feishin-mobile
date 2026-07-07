import 'package:freezed_annotation/freezed_annotation.dart';

part 'gain_info.freezed.dart';
part 'gain_info.g.dart';

/// Mirrors `GainInfo` in feishin/src/shared/types/domain-types.ts.
@freezed
abstract class GainInfo with _$GainInfo {
  const factory GainInfo({double? album, double? track}) = _GainInfo;

  factory GainInfo.fromJson(Map<String, dynamic> json) =>
      _$GainInfoFromJson(json);
}
