import 'package:pay_pos/models/place.dart';
import 'package:pay_pos/state/places/places.dart';

List<Place> selectFilteredPlaces(PlacesState state) =>
    List<Place>.from(state.places)
        .where((place) =>
            place.name.toLowerCase().contains(state.searchQuery.toLowerCase()))
        .toList();
