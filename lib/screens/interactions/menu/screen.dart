import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:pay_pos/state/place_order.dart';
import 'package:pay_pos/theme/colors.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'package:pay_pos/state/checkout.dart';

import 'footer.dart';
import 'menu_list_item.dart';
import 'catergory_scroll.dart';

// reference: https://github.com/AmirBayat0/flutter_scroll_animation

class PlaceMenuScreen extends StatefulWidget {
  final String placeId;

  const PlaceMenuScreen({
    super.key,
    required this.placeId,
  });

  @override
  State<PlaceMenuScreen> createState() => _PlaceMenuScreenState();
}

class _PlaceMenuScreenState extends State<PlaceMenuScreen> {
  final ScrollController _menuScrollController = ScrollController();

  final ItemScrollController tabScrollController = ItemScrollController();
  final ItemPositionsListener tabPositionsListener =
      ItemPositionsListener.create();

  final ScrollOffsetController tabScrollOffsetController =
      ScrollOffsetController();

  int _selectedIndex = 0;

  String _currentVisibleCategory = '';
  Timer? _scrollThrottle;

  static const double headerHeight = _StickyHeaderDelegate.height;
  static const double detectionSensitivity = 0.5; // 0.5 = half header height

  double get _scrollThreshold => headerHeight * (1 + detectionSensitivity);

  @override
  void initState() {
    super.initState();

    _menuScrollController.addListener(_throttledOnScroll);

    tabPositionsListener.itemPositions.addListener(_onItemPositionsChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {});
  }

  void onLoad() {
    final placeMenu = context.read<PlaceOrderState>().placeMenu;
    if (placeMenu == null) return;
    _currentVisibleCategory = placeMenu.categories[0];
  }

  void _onPayPressed() {
    final navigator = GoRouter.of(context);
    print("pushing to pay");
    navigator.push('/${widget.placeId}/true/pay');
  }

  @override
  void dispose() {
    tabPositionsListener.itemPositions.removeListener(_onItemPositionsChange);

    _scrollThrottle?.cancel();
    _menuScrollController.removeListener(_throttledOnScroll);
    _menuScrollController.dispose();

    super.dispose();
  }

  void goBack() {
    Navigator.pop(context);
  }

  void _onScroll() {
    // TODO: see if there is a better way to access these state variables
    final categoryKeys = context.read<PlaceOrderState>().categoryKeys;
    final placeMenu = context.read<PlaceOrderState>().placeMenu;
    if (placeMenu == null) return;

    final headerContexts =
        categoryKeys.map((key) => key.currentContext).toList();

    for (int i = 0; i < headerContexts.length; i++) {
      if (headerContexts[i] == null) continue;

      final RenderObject? renderObject = headerContexts[i]!.findRenderObject();
      if (renderObject == null) continue;

      // Get the viewport position using RenderSliver instead of RenderBox
      final RenderAbstractViewport viewport =
          RenderAbstractViewport.of(renderObject);
      final double viewportOffset =
          viewport.getOffsetToReveal(renderObject, 0.0).offset;
      final double scrollOffset = _menuScrollController.offset;

      // Check if this header is near the top of the viewport
      if ((scrollOffset - viewportOffset).abs() < _scrollThreshold) {
        // adjust threshold as needed
        final category = placeMenu.categories[i];
        if (_currentVisibleCategory != category) {
          setState(() {
            _currentVisibleCategory = category;
            _selectedIndex = i;
          });
          tabScrollController.scrollTo(
              index: i, duration: const Duration(milliseconds: 600));
        }
        break;
      }
    }
  }

  void _throttledOnScroll() {
    if (_scrollThrottle?.isActive ?? false) return;
    _scrollThrottle = Timer(const Duration(milliseconds: 100), () {
      _onScroll();
    });
  }

  void _onItemPositionsChange() {
    tabPositionsListener.itemPositions.value.first.index;
  }

  void onCategorySelected(
      int index, List<GlobalKey<State<StatefulWidget>>> categoryKeys) async {
    _menuScrollController.removeListener(_onScroll);
    setState(() {
      _selectedIndex = index;
    });

    tabScrollController.scrollTo(
        index: index, duration: const Duration(milliseconds: 600));

    final categories = categoryKeys[index].currentContext!;
    await Scrollable.ensureVisible(
      categories,
      duration: const Duration(milliseconds: 600),
    );

    _menuScrollController.addListener(_onScroll);
  }

  @override
  Widget build(BuildContext context) {
    final categoryKeys = context.watch<PlaceOrderState>().categoryKeys;
    final placeMenu = context.watch<PlaceOrderState>().placeMenu;

    final checkoutState = context.watch<CheckoutState>();
    // final place = context.watch<PlaceOrderState>().place?.place;
    final menuItems = context.watch<PlaceOrderState>().place?.items ?? [];
    // final profile = context.watch<PlaceOrderState>().place?.profile;
    final checkout = checkoutState.checkout;
    final checkoutTotal = checkout.total;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      child: SafeArea(
        child: Column(
          children: [
            // ChatHeader(
            //   imageUrl: profile?.imageUrl ?? place?.imageUrl ?? '',
            //   placeName: profile?.name ?? place?.name ?? '',
            //   placeDescription:
            //       profile?.description ?? place?.description ?? '',
            //   onTapLeading: goBack,
            // ),

            CategoryScroll(
              categories: placeMenu?.categories ?? [],
              tabScrollController: tabScrollController,
              tabPositionsListener: tabPositionsListener,
              tabScrollOffsetController: tabScrollOffsetController,
              onSelected: (index) => onCategorySelected(index, categoryKeys),
              selectedIndex: _selectedIndex,
            ),

            // Menu items grouped by category
            Expanded(
              child: CustomScrollView(
                controller: _menuScrollController,
                slivers: [
                  for (var category in placeMenu?.categories ?? [])
                    SliverMainAxisGroup(
                      slivers: [
                        SliverPersistentHeader(
                          key: categoryKeys[
                              (placeMenu?.categories ?? []).indexOf(category)],
                          pinned: true,
                          delegate: _StickyHeaderDelegate(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: whiteColor.withValues(alpha: 0.95),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    category,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final items = menuItems
                                  .where((item) => item.category == category)
                                  .toList();
                              if (index >= items.length) return null;
                              return MenuListItem(
                                menuItem: items[index],
                                checkoutState: checkoutState,
                              );
                            },
                            childCount: menuItems
                                .where((item) => item.category == category)
                                .length,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Footer(
              checkoutTotal: checkoutTotal,
              onSend: () {
                _onPayPressed();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  static const double height = 42.0; // Fixed height constant

  _StickyHeaderDelegate({
    required this.child,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox(
      height: height,
      child: child,
    );
  }

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) {
    return true;
  }
}
