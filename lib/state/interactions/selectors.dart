import 'package:pay_pos/models/interaction.dart';
import 'package:pay_pos/state/interactions/interactions.dart';

List<Interaction> sortByUnreadAndDate(InteractionState state) {
  return List<Interaction>.from(state.interactions)
      .where((interaction) => interaction.name
          .toLowerCase()
          .contains(state.searchQuery.toLowerCase()))
      .toList();
}
