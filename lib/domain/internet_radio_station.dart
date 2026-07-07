import 'package:freezed_annotation/freezed_annotation.dart';

part 'internet_radio_station.freezed.dart';
part 'internet_radio_station.g.dart';

/// Mirrors `InternetRadioStation` in
/// feishin/src/shared/types/domain-types.ts.
@freezed
abstract class InternetRadioStation with _$InternetRadioStation {
  const factory InternetRadioStation({
    required String? homepageUrl,
    required String id,
    String? imageId,
    String? imageUrl,
    required String name,
    required String streamUrl,
    String? uploadedImage,
  }) = _InternetRadioStation;

  factory InternetRadioStation.fromJson(Map<String, dynamic> json) =>
      _$InternetRadioStationFromJson(json);
}
