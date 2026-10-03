import 'package:grocery_app/localization/localized_material.dart';
import 'package:get/get.dart';
import 'package:grocery_app/controllers/language_controller.dart';
import 'package:grocery_app/controllers/banner_controller.dart';
import 'package:grocery_app/controllers/category_controller.dart';
import 'package:grocery_app/controllers/login_controller.dart';
import 'package:grocery_app/controllers/notification_controller.dart';
import 'package:grocery_app/controllers/product_controller.dart';
import 'package:grocery_app/controllers/store_controller.dart';
import 'package:grocery_app/generated/l10n.dart';
import 'package:grocery_app/helpers/responsive_layout.dart';
import 'package:grocery_app/localization/catalog_localization.dart';
import 'package:grocery_app/models/category_model.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/controllers/navigation_controller.dart';
import 'package:grocery_app/screens/category_items_screen.dart';
import 'package:grocery_app/screens/product_details/product_details_screen.dart';
import 'package:grocery_app/styles/colors.dart';
import 'package:grocery_app/controllers/network_status_controller.dart';
import 'package:grocery_app/widgets/app_network_image.dart';
import 'package:grocery_app/widgets/banner_media.dart';
import 'package:grocery_app/widgets/grocery_item_card_widget.dart';
import 'package:grocery_app/widgets/no_internet_widget.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shimmer/shimmer.dart';
import 'category_cart.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'notification_list_screen.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});

  final BannerController bannerController = Get.put(BannerController());
  final StoreController storeController = Get.put(StoreController());
  final CategoryController categoryController = Get.put(CategoryController());
  final ProductController productController = Get.put(ProductController());
  final LanguageController languageController = Get.put(LanguageController());
  final NotificationController notificationController = Get.put(
    NotificationController(),
  );

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Color> gridColors = [
    Color(0xFFFF762D),
    Color(0xffF8A44C),
    Color(0xffF7A593),
    Color(0xffD3B0E0),
    Color(0xffFDE598),
    Color(0xffB7DFF5),
    Color(0xff836AF6),
    Color(0xffD73B77),
  ];

  final RefreshController _refreshController = RefreshController();
  final RxInt _currentBannerIndex = 0.obs;

  final LoginController loginController = Get.find<LoginController>();
  final NavigationController navigationController =
      Get.find<NavigationController>();

  String _shortenText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}…';
  }

  Widget _buildLocationSelector(BuildContext context) {
    return Obx(() {
      final selectedId = widget.storeController.selectedLocationId.value;
      final isAll = selectedId == 0;
      final store = isAll ? null : widget.storeController.selectedStore;
      final isKhmer =
          widget.languageController.currentLanguageCode.value == 'km';

      final displayName = isAll
          ? (isKhmer ? 'សាខាទាំងអស់' : 'All Branches')
          : (store == null ? 'All Branches' : store.localizedName(context));

      final deliverToLabel = isKhmer ? 'សាខាហាង' : 'SELECT BRANCH';

      return GestureDetector(
        onTap: () => _showLocationSelector(context),
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    deliverToLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85),
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          _shortenText(displayName, 18),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildNotification(BuildContext context) {
    return InkWell(
      onTap: () {
        if (loginController.isAuthenticated.value) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NotificationListScreen()),
          );
        } else {
          navigationController.currentIndex.value = 4;
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: 38,
        height: 38,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.notifications_outlined,
              size: 30,
              color: Colors.white,
            ),
            Positioned(
              right: 0,
              top: 0,
              child: Obx(() {
                final unread = widget.notificationController.notifications
                    .where((n) => n.readAt == null)
                    .length;

                if (unread == 0) return const SizedBox.shrink();

                final badgeText = unread > 9 ? "9+" : unread.toString();

                return Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFEF4444),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Center(
                    child: Text(
                      badgeText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final isKhmer = widget.languageController.currentLanguageCode.value == 'km';
    final hint = isKhmer
        ? 'ស្វែងរកទំនិញស្រស់ៗ...'
        : 'Search store, fresh groceries...';

    return GestureDetector(
      onTap: () {
        navigationController.currentIndex.value = 1;
      },
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              color: AppColors.primaryColor,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hint,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: Color(0xFF64748B),
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveLayout.horizontalPadding(context);
    final contentMaxWidth = ResponsiveLayout.maxContentWidth(context);
    final carouselHeight = ResponsiveLayout.isTablet(context) ? 220.0 : 180.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 64,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF762D), Color(0xFFFF8E42)],
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
        ),
        titleSpacing: 16,
        title: _buildLocationSelector(context),
        actions: [_buildNotification(context), const SizedBox(width: 16)],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: _buildSearchBar(context),
          ),
        ),
      ),
      body: SmartRefresher(
        controller: _refreshController,
        enablePullDown: true,
        header: const ClassicHeader(height: 0),
        onRefresh: () async {
          if (Get.isRegistered<NetworkStatusController>()) {
            await Get.find<NetworkStatusController>().retry();
          } else {
            widget.bannerController.fetchInitData();
            widget.storeController.fetchInitData();
            widget.categoryController.fetchInitData();
            widget.productController.fetchInitData();
          }
          _refreshController.refreshCompleted();
        },
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentMaxWidth),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 18),
                    Obx(() {
                      final isLoading = widget.bannerController.isLoading.value;
                      final banners = widget.bannerController.banners;

                      final carouselOptions = CarouselOptions(
                        height: carouselHeight,
                        enlargeCenterPage: false,
                        viewportFraction: 1.0,
                        autoPlay: !isLoading && banners.length > 1,
                        aspectRatio: 16 / 9,
                        autoPlayCurve: Curves.fastOutSlowIn,
                        enableInfiniteScroll: !isLoading && banners.length > 1,
                        autoPlayAnimationDuration: const Duration(
                          milliseconds: 800,
                        ),
                        onPageChanged: (index, reason) {
                          _currentBannerIndex.value = index;
                        },
                      );

                      if (isLoading) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Shimmer.fromColors(
                            baseColor: Colors.grey.shade300,
                            highlightColor: Colors.grey.shade100,
                            child: Container(
                              width: double.infinity,
                              height: carouselHeight,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade400,
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),
                        );
                      }

                      if (banners.isEmpty) return const SizedBox.shrink();

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CarouselSlider.builder(
                            itemCount: banners.length,
                            itemBuilder: (context, index, realIndex) {
                              final banner = banners[index];
                              final hasText =
                                  (banner.title != null &&
                                      banner.title!.isNotEmpty) ||
                                  (banner.badge != null &&
                                      banner.badge!.isNotEmpty) ||
                                  (banner.subtitle != null &&
                                      banner.subtitle!.isNotEmpty) ||
                                  (banner.discount != null &&
                                      banner.discount!.isNotEmpty);
                              final fallbackColors = (index % 3 == 0)
                                  ? const [Color(0xFF15803D), Color(0xFF22C55E)]
                                  : (index % 3 == 1)
                                  ? const [Color(0xFFC2410C), Color(0xFFF97316)]
                                  : const [
                                      Color(0xFFB45309),
                                      Color(0xFFF59E0B),
                                    ];

                              return Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.08,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Positioned.fill(
                                        child: BannerMedia(
                                          key: ValueKey(
                                            '${banner.id}-${banner.mediaType}-${banner.image}',
                                          ),
                                          banner: banner,
                                          fallbackColors: fallbackColors,
                                        ),
                                      ),
                                      if (hasText) ...[
                                        IgnorePointer(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                                colors: [
                                                  Colors.black.withValues(
                                                    alpha: 0.45,
                                                  ),
                                                  Colors.black.withValues(
                                                    alpha: 0.15,
                                                  ),
                                                  Colors.transparent,
                                                ],
                                                stops: const [0.0, 0.5, 1.0],
                                              ),
                                            ),
                                          ),
                                        ),
                                        IgnorePointer(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 18,
                                              vertical: 14,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                if (banner.badge != null &&
                                                    banner.badge!.isNotEmpty)
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 9,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          bannerColor(
                                                            banner.badgeBg,
                                                          ) ??
                                                          const Color(
                                                            0xF2FF762D,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color:
                                                              (bannerColor(
                                                                        banner
                                                                            .badgeBg,
                                                                      ) ??
                                                                      const Color(
                                                                        0xFFFF762D,
                                                                      ))
                                                                  .withValues(
                                                                    alpha: 0.35,
                                                                  ),
                                                          blurRadius: 4,
                                                          offset: const Offset(
                                                            0,
                                                            2,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Text(
                                                      banner.badge!
                                                          .toUpperCase(),
                                                      style: TextStyle(
                                                        color:
                                                            bannerColor(
                                                              banner.badgeColor,
                                                            ) ??
                                                            Colors.white,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        letterSpacing: 0.6,
                                                      ),
                                                    ),
                                                  ),
                                                if (banner.title != null &&
                                                    banner
                                                        .title!
                                                        .isNotEmpty) ...[
                                                  const SizedBox(height: 6),
                                                  ConstrainedBox(
                                                    constraints: BoxConstraints(
                                                      maxWidth:
                                                          MediaQuery.of(
                                                            context,
                                                          ).size.width *
                                                          0.58,
                                                    ),
                                                    child: Text(
                                                      banner.title!,
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        height: 1.2,
                                                        shadows: [
                                                          Shadow(
                                                            offset: Offset(
                                                              0,
                                                              1,
                                                            ),
                                                            blurRadius: 4,
                                                            color:
                                                                Colors.black54,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                                if (banner.subtitle != null &&
                                                    banner
                                                        .subtitle!
                                                        .isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  ConstrainedBox(
                                                    constraints: BoxConstraints(
                                                      maxWidth:
                                                          MediaQuery.of(
                                                            context,
                                                          ).size.width *
                                                          0.66,
                                                    ),
                                                    child: Text(
                                                      banner.subtitle!,
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        color: Colors.white
                                                            .withValues(
                                                              alpha: 0.92,
                                                            ),
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        height: 1.15,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                                if (banner.discount != null &&
                                                    banner
                                                        .discount!
                                                        .isNotEmpty) ...[
                                                  const SizedBox(height: 6),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 3,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black
                                                          .withValues(
                                                            alpha: 0.4,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      banner.discount!,
                                                      style: const TextStyle(
                                                        color: Color(
                                                          0xFFFFB74D,
                                                        ),
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        letterSpacing: 0.4,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                            options: carouselOptions,
                          ),
                          if (banners.length > 1) ...[
                            const SizedBox(height: 10),
                            Obx(() {
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(banners.length, (
                                  index,
                                ) {
                                  final isActive =
                                      _currentBannerIndex.value == index;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    height: 6,
                                    width: isActive ? 18 : 6,
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? AppColors.primaryColor
                                          : Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  );
                                }),
                              );
                            }),
                          ],
                        ],
                      );
                    }),
                    Obx(() {
                      final hasNoData =
                          widget.categoryController.categories.isEmpty &&
                          widget.productController.newP.isEmpty &&
                          widget.productController.bestSell.isEmpty &&
                          !widget.productController.isLoading.value;
                      final isOffline =
                          Get.isRegistered<NetworkStatusController>() &&
                          Get.find<NetworkStatusController>()
                              .isUnavailable
                              .value;

                      if (hasNoData && isOffline) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: NoInternetWidget(
                            onRetry: () =>
                                Get.find<NetworkStatusController>().retry(),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                    const SizedBox(height: 20),
                    _buildSubTitle(
                      S.of(context).category,
                      context,
                      onSeeAll: () {
                        navigationController.currentIndex.value = 1;
                      },
                    ),
                    const SizedBox(height: 14),
                    Obx(() {
                      return _buildFeaturedCategories(
                        widget.categoryController.categories,
                        isLoading: widget.categoryController.isLoading.value,
                      );
                    }),
                    const SizedBox(height: 22),
                    _buildSubTitle(
                      S.of(context).new_arrival,
                      context,
                      onSeeAll: () {
                        navigationController.currentIndex.value = 1;
                      },
                    ),
                    Obx(() {
                      return _buildHorizontalItemSlider(
                        widget.productController.newP,
                        isLoading: widget.productController.isLoading.value,
                        section: 'new',
                      );
                    }),
                    const SizedBox(height: 16),
                    _buildSubTitle(
                      S.of(context).best_sell,
                      context,
                      onSeeAll: () {
                        navigationController.currentIndex.value = 1;
                      },
                    ),
                    Obx(() {
                      return _buildHorizontalItemSlider(
                        widget.productController.bestSell,
                        isLoading: widget.productController.isLoading.value,
                        section: 'best',
                      );
                    }),
                    const SizedBox(height: 16),
                    Obx(() {
                      return _buildHorizontalItemSlider(
                        widget.productController.bestSell2,
                        isLoading: widget.productController.isLoading.value,
                        section: 'rec',
                      );
                    }),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubTitle(
    String text,
    BuildContext context, {
    VoidCallback? onSeeAll,
  }) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        const Spacer(),
        InkWell(
          onTap: onSeeAll,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  S.of(context).see_all,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 11,
                  color: AppColors.primaryColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedCategories(
    List<CategoryModel> categories, {
    bool isLoading = false,
  }) {
    final lengthCategory = isLoading ? 5 : categories.length;
    final isTablet = ResponsiveLayout.isTablet(context);
    final cardWidth = ResponsiveLayout.featuredCategoryCardWidth(context);
    final cardHeight = isTablet ? 115.0 : 105.0;

    return SizedBox(
      height: cardHeight,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        scrollDirection: Axis.horizontal,
        itemCount: lengthCategory,
        itemBuilder: (context, index) {
          if (isLoading) {
            return SizedBox(
              width: cardWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      height: 12,
                      width: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            final category = categories[index];
            return CategoryCard(
              category,
              width: cardWidth,
              height: cardHeight,
              color: gridColors[index % gridColors.length],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CategoryItemsScreen(
                      categoryName: category.localizedName(context),
                    ),
                  ),
                );
              },
            );
          }
        },
        separatorBuilder: (context, index) => const SizedBox(width: 14),
      ),
    );
  }

  Widget _buildHorizontalItemSlider(
    List<ProductModel> items, {
    bool isLoading = false,
    String section = 'home',
  }) {
    final selectedBranchId = widget.storeController.selectedLocationId.value;
    final filteredItems = selectedBranchId > 0
        ? items.where((p) => p.branchId == selectedBranchId).toList()
        : items;
    final itemCount = isLoading ? 5 : filteredItems.length;
    final cardWidth = ResponsiveLayout.productCarouselCardWidth(context);
    final cardHeight = ResponsiveLayout.isTablet(context) ? 300.0 : 272.0;

    if (!isLoading && filteredItems.isEmpty) {
      return const Center(child: Text("No items found"));
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      height: cardHeight,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (isLoading) {
            return Container(
              width: cardWidth,
              height: cardHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.grey.shade200, // light background for card
              ),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      height: 16,
                      width: double.infinity,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      height: 14,
                      width: cardWidth * 0.6,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: Container(
                          height: 18,
                          width: 50,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const Spacer(),
                      Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: Container(
                          height: 30,
                          width: 30,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          } else {
            final item = filteredItems[index];
            final heroSuffix = "home-$section-${item.id}-$index";
            return GestureDetector(
              onTap: () => _onItemClicked(context, item, heroSuffix),
              child: SizedBox(
                width: cardWidth,
                child: GroceryItemCardWidget(
                  item: item,
                  heroSuffix: heroSuffix,
                ),
              ),
            );
          }
        },
        separatorBuilder: (_, __) => const SizedBox(width: 16),
      ),
    );
  }

  void _onItemClicked(
    BuildContext context,
    ProductModel groceryItem,
    String heroSuffix,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ProductDetailsScreen(groceryItem, heroSuffix: heroSuffix),
      ),
    );
  }

  void _showLocationSelector(BuildContext context) {
    if (widget.storeController.stores.isEmpty) {
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // important for dynamic height
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // Calculate max height (e.g., 60% of screen)
        final maxHeight = MediaQuery.of(context).size.height * 0.6;

        return LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              constraints: BoxConstraints(maxHeight: maxHeight),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Text(
                    S.of(context).select_location,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  // Wrap list in Flexible + SingleChildScrollView for dynamic scrolling
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: widget.storeController.stores.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          final isSelected =
                              widget.storeController.selectedLocationId.value ==
                              0;
                          return GestureDetector(
                            onTap: () {
                              widget.storeController.updateSelectedStore(0);
                              Navigator.pop(context);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              height: 72,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: isSelected
                                    ? AppColors.primaryLight
                                    : Colors.grey[100],
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryColor
                                      : Colors.grey.shade300,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12),
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryColor
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.store_mall_directory_outlined,
                                        color: AppColors.primaryColor,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          widget
                                                      .languageController
                                                      .currentLanguageCode
                                                      .value ==
                                                  'km'
                                              ? 'សាខាទាំងអស់'
                                              : 'All Branches',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          widget
                                                      .languageController
                                                      .currentLanguageCode
                                                      .value ==
                                                  'km'
                                              ? 'បង្ហាញទំនិញពីគ្រប់សាខា'
                                              : 'Show products from all branches',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 16),
                                      child: Icon(
                                        Icons.check_circle,
                                        color: AppColors.primaryColor,
                                        size: 20,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }

                        final storeIndex = index - 1;
                        final color =
                            gridColors[storeIndex % gridColors.length];
                        final loc = widget.storeController.stores[storeIndex];
                        final isSelected =
                            widget.storeController.selectedLocationId.value ==
                            loc.id;
                        final displayName = loc.localizedName(context);

                        return GestureDetector(
                          onTap: () {
                            widget.storeController.updateSelectedStore(loc.id);
                            Navigator.pop(context);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            height: 72,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: isSelected
                                  ? AppColors.primaryLight
                                  : Colors.grey[100],
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryColor
                                    : color.withValues(alpha: 0.2),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 12),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: AppNetworkImage(
                                      image: loc.image,
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.cover,
                                      fallbackIcon: Icons.storefront_outlined,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        displayName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            size: 13,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              loc.description.isNotEmpty
                                                  ? loc.description
                                                  : 'Store branch',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 16),
                                    child: Icon(
                                      Icons.check_circle,
                                      color: AppColors.primaryColor,
                                      size: 20,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
