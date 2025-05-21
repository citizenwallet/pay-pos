import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:pay_pos/theme/colors.dart';
import 'package:provider/provider.dart';

//states
import 'package:pay_pos/state/orders.dart';
import 'package:pay_pos/state/place_order.dart';
import 'package:pay_pos/state/checkout.dart';

//widgets
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
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

  late OrdersState _ordersState;

  static const double headerHeight = _StickyHeaderDelegate.height;
  static const double detectionSensitivity = 0.5; // 0.5 = half header height

  double get _scrollThreshold => headerHeight * (1 + detectionSensitivity);

  @override
  void initState() {
    super.initState();
    _ordersState = context.read<OrdersState>();

    _menuScrollController.addListener(_throttledOnScroll);

    tabPositionsListener.itemPositions.addListener(_onItemPositionsChange);

    _ordersState.isPollingEnabled = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {});
  }

  void onLoad() {
    final placeMenu = context.read<PlaceOrderState>().placeMenu;

    if (placeMenu == null) return;
    _currentVisibleCategory = placeMenu.categories[0];
  }

  Future<void> _handlePay(List<Map<String, dynamic>> items, String description,
      double total, String account) async {
    final orderId = await _ordersState.createOrder(
      items: items,
      description: description,
      total: total,
      account: account,
    );

    context.go('/${widget.placeId}/order/$orderId/pay', extra: {
      'items': items,
      'amount': total,
      'description': description,
    });
  }

  @override
  void dispose() {
    tabPositionsListener.itemPositions.removeListener(_onItemPositionsChange);
    _scrollThrottle?.cancel();
    _menuScrollController.removeListener(_throttledOnScroll);
    _menuScrollController.dispose();
    _ordersState.isPollingEnabled = true;

    super.dispose();
  }

  void goBack() {
    context.go('/${widget.placeId}');
  }

  void _onScroll() {
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
            index: i,
            duration: const Duration(milliseconds: 600),
          );
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

    final place = context.watch<PlaceOrderState>().place;

    final placeMenu = context.watch<PlaceOrderState>().placeMenu;

    final checkoutState = context.watch<CheckoutState>();

    final menuItems = context.watch<PlaceOrderState>().place?.items ?? [];

    final checkout = checkoutState.checkout;

    final checkoutTotal = checkout.total;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      child: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 10,
                ),
                GestureDetector(
                  onTap: goBack,
                  child: LeftChevron(),
                ),
              ],
            ),
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
                final items = checkout.items
                    .map((item) => {
                          'id': item.menuItem.id,
                          'quantity': item.quantity,
                        })
                    .toList();
                _handlePay(items, "", checkout.total, place!.place.account);
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

class LeftChevron extends StatelessWidget {
  const LeftChevron({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    return Icon(
      CupertinoIcons.chevron_left,
      color: theme.primaryColor,
      size: 16,
    );
  }
}
