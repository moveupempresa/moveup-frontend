import 'event.dart';
import 'popular_profile.dart';

class ExploreSections {
  final List<Event> nearYou;
  final List<Event> newest;
  final List<Event> popular;
  final List<Event> forYou;
  final List<PopularProfile> popularProfiles;

  const ExploreSections({
    required this.nearYou,
    required this.newest,
    required this.popular,
    required this.forYou,
    required this.popularProfiles,
  });

  bool get isEmpty =>
      nearYou.isEmpty && newest.isEmpty && popular.isEmpty && forYou.isEmpty && popularProfiles.isEmpty;

  factory ExploreSections.fromJson(Map<String, dynamic> json) => ExploreSections(
        nearYou: (json['nearYou'] as List<dynamic>)
            .map((e) => Event.fromJson(e as Map<String, dynamic>))
            .toList(),
        newest: (json['newest'] as List<dynamic>)
            .map((e) => Event.fromJson(e as Map<String, dynamic>))
            .toList(),
        popular: (json['popular'] as List<dynamic>)
            .map((e) => Event.fromJson(e as Map<String, dynamic>))
            .toList(),
        forYou: (json['forYou'] as List<dynamic>)
            .map((e) => Event.fromJson(e as Map<String, dynamic>))
            .toList(),
        popularProfiles: (json['popularProfiles'] as List<dynamic>)
            .map((p) => PopularProfile.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}
