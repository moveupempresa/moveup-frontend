import 'event.dart';
import 'popular_profile.dart';

class ExploreSections {
  final List<Event> nearYou;
  final List<Event> newest;
  final List<Event> popular;
  final List<Event> forYou;
  final List<Event> castings;
  final List<PopularProfile> popularProfiles;
  final bool viewerHasLocation;

  const ExploreSections({
    required this.nearYou,
    required this.newest,
    required this.popular,
    required this.forYou,
    required this.castings,
    required this.popularProfiles,
    required this.viewerHasLocation,
  });

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
        castings: (json['castings'] as List<dynamic>)
            .map((e) => Event.fromJson(e as Map<String, dynamic>))
            .toList(),
        popularProfiles: (json['popularProfiles'] as List<dynamic>)
            .map((p) => PopularProfile.fromJson(p as Map<String, dynamic>))
            .toList(),
        viewerHasLocation: json['viewerHasLocation'] as bool,
      );
}
