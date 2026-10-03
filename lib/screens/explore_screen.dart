import 'dart:async';
import 'package:grocery_app/localization/localized_material.dart';
import 'package:get/get.dart';
import 'package:grocery_app/controllers/category_controller.dart';
import 'package:grocery_app/controllers/language_controller.dart';
import 'package:grocery_app/controllers/product_controller.dart';
import 'package:grocery_app/controllers/store_controller.dart';
import 'package:grocery_app/data/mock_data.dart';
import 'package:grocery_app/helpers/responsive_layout.dart';
import 'package:grocery_app/localization/catalog_localization.dart';
import 'package:grocery_app/models/category_item.dart';
import 'package:grocery_app/models/category_model.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/screens/category_items_screen.dart';
import 'package:grocery_app/services/mobile_api_repository.dart';
import 'package:grocery_app/controllers/network_status_controller.dart';
import 'package:grocery_app/styles/colors.dart';
import 'package:grocery_app/widgets/category_item_card_widget.dart';
import 'package:grocery_app/widgets/grocery_item_card_widget.dart';
import 'package:grocery_app/widgets/no_internet_widget.dart';

List<Color> gridColors = [
  const Color(0xFFFF762D),
  const Color(0xffF8A44C),
  const Color(0xffF7A593),
  const Color(0xffD3B0E0),
  const Color(0xffFDE598),
  const Color(0xffB7DFF5),
  const Color(0xff836AF6),
  const Color(0xffD73B77),
];

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final MobileApiRepository _apiRepository = MobileApiRepository();

  final LanguageController languageController = Get.find<LanguageController>();
  final CategoryController categoryController = Get.find<CategoryController>();
  final ProductController productController = Get.find<ProductController>();

  Timer? _debounceTimer;
  String query = '';
  String _activeSearchKeyword = '';
  List<ProductModel> _searchResults = [];
  bool _isSearching = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalResults = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 250) {
      if (!_isLoadingMore && !_isSearching && _currentPage < _lastPage) {
        _loadMore();
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _debounceTimer?.cancel();
    final trimmed = val.trim();
    if (trimmed.isEmpty) {
      setState(() {
        query = '';
        _activeSearchKeyword = '';
        _searchResults = [];
        _isSearching = false;
        _isLoadingMore = false;
        _currentPage = 1;
        _lastPage = 1;
        _totalResults = 0;
      });
      return;
    }

    setState(() {
      query = val;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _executeSearch(trimmed);
    });
  }

  void _onSearchSubmitted(String val) {
    _debounceTimer?.cancel();
    final trimmed = val.trim();
    if (trimmed.isEmpty) return;
    _executeSearch(trimmed);
  }

  void _clearSearch() {
    _debounceTimer?.cancel();
    _searchController.clear();
    setState(() {
      query = '';
      _activeSearchKeyword = '';
      _searchResults = [];
      _isSearching = false;
      _isLoadingMore = false;
      _currentPage = 1;
      _lastPage = 1;
      _totalResults = 0;
    });
  }

  Future<void> _executeSearch(String keyword) async {
    final storeController = Get.find<StoreController>();
    final selectedBranchId = storeController.selectedLocationId.value;
    final branchIdParam = selectedBranchId > 0 ? selectedBranchId : null;

    setState(() {
      _isSearching = true;
      _activeSearchKeyword = keyword;
      _currentPage = 1;
      _searchResults = [];
    });

    try {
      final response = await _apiRepository.fetchProductsPaginated(
        search: keyword,
        page: 1,
        perPage: 20,
        branchId: branchIdParam,
      );

      MockDataRepository.updateProducts(response.items);

      if (mounted && _activeSearchKeyword == keyword) {
        setState(() {
          _searchResults = List<ProductModel>.from(response.items);
          _currentPage = response.currentPage;
          _lastPage = response.lastPage;
          _totalResults = response.total;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted && _activeSearchKeyword == keyword) {
        // Fallback: If network fails, search local products so user is not blocked
        final matchingLocal = productController.shopProducts.where((prod) {
          if (selectedBranchId > 0 && prod.branchId != selectedBranchId) {
            return false;
          }
          return prod.name.toLowerCase().contains(keyword.toLowerCase()) ||
              (prod.khName?.toLowerCase().contains(keyword.toLowerCase()) ??
                  false) ||
              prod.description.toLowerCase().contains(keyword.toLowerCase()) ||
              prod.categoryEn.toLowerCase().contains(keyword.toLowerCase()) ||
              prod.categoryKh.toLowerCase().contains(keyword.toLowerCase());
        }).toList(growable: false);

        setState(() {
          _searchResults = matchingLocal;
          _currentPage = 1;
          _lastPage = 1;
          _totalResults = matchingLocal.length;
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore ||
        _currentPage >= _lastPage ||
        _activeSearchKeyword.isEmpty) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    final currentKeyword = _activeSearchKeyword;
    final nextPage = _currentPage + 1;
    final storeController = Get.find<StoreController>();
    final selectedBranchId = storeController.selectedLocationId.value;
    final branchIdParam = selectedBranchId > 0 ? selectedBranchId : null;

    try {
      final response = await _apiRepository.fetchProductsPaginated(
        search: currentKeyword,
        page: nextPage,
        perPage: 20,
        branchId: branchIdParam,
      );

      MockDataRepository.updateProducts(response.items);

      if (mounted && _activeSearchKeyword == currentKeyword) {
        setState(() {
          _searchResults.addAll(response.items);
          _currentPage = response.currentPage;
          _lastPage = response.lastPage;
          _totalResults = response.total;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveLayout.horizontalPadding(context);
    final contentMaxWidth = ResponsiveLayout.maxContentWidth(context);
    final isKhmer = languageController.currentLanguageCode.value == 'km';

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
              colors: [
                Color(0xFFFF762D),
                Color(0xFFFF8E42),
              ],
            ),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
          ),
        ),
        centerTitle: false,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isKhmer ? 'ស្វែងរកទំនិញ' : 'Find Products',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isKhmer
                  ? 'រុករកទំនិញស្រស់ៗ និងប្រភេទទាំងអស់'
                  : 'Explore fresh groceries & goods',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: _buildSearchBar(isKhmer),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentMaxWidth),
          child: query.trim().isEmpty
              ? _buildDefaultCategoryView(context, horizontalPadding, isKhmer)
              : _buildSearchResultsView(context, horizontalPadding, isKhmer),
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isKhmer) {
    return Container(
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
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: _onSearchChanged,
              onSubmitted: _onSearchSubmitted,
              decoration: InputDecoration(
                hintText: isKhmer
                    ? 'ស្វែងរកប្រភេទ ឬទំនិញ...'
                    : 'Search categories or products...',
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (query.isNotEmpty)
            GestureDetector(
              onTap: _clearSearch,
              child: const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(
                  Icons.cancel_rounded,
                  color: Color(0xFF94A3B8),
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDefaultCategoryView(
      BuildContext context, double horizontalPadding, bool isKhmer) {
    return SingleChildScrollView(
      padding:
          EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isKhmer ? 'ប្រភេទទាំងអស់' : 'All Categories',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Obx(() => Text(
                      '${categoryController.categories.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    )),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Obx(() {
            final categories = categoryController.categories;
            if (categoryController.isLoading.value) {
              return _buildShimmerGrid(context);
            }
            if (categories.isEmpty) {
              if (Get.isRegistered<NetworkStatusController>() &&
                  Get.find<NetworkStatusController>().isUnavailable.value) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: NoInternetWidget(
                    onRetry: () => categoryController.fetchInitData(),
                  ),
                );
              }
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No categories found'),
                ),
              );
            }
            return _buildCategoryGrid(context, categories);
          }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSearchResultsView(
      BuildContext context, double horizontalPadding, bool isKhmer) {
    final keyword = query.trim().toLowerCase();

    final matchingCategories = categoryController.categories.where((cat) {
      final khName = cat.khName ?? '';
      return cat.name.toLowerCase().contains(keyword) ||
          khName.toLowerCase().contains(keyword);
    }).toList(growable: false);

    return SingleChildScrollView(
      controller: _scrollController,
      padding:
          EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (matchingCategories.isNotEmpty) ...[
            Text(
              isKhmer ? 'ប្រភេទដែលត្រូវគ្នា' : 'Matching Categories',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: matchingCategories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = matchingCategories[index];
                  final displayName = cat.localizedName(context);
                  return GestureDetector(
                    onTap: () => onCategoryItemClicked(context, cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.category_rounded,
                            size: 16,
                            color: AppColors.primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (_isSearching) ...[
            Row(
              children: [
                Text(
                  isKhmer ? 'កំពុងស្វែងរក...' : 'Searching products...',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 10),
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildProductShimmerGrid(context),
          ] else if (_searchResults.isNotEmpty) ...[
            Row(
              children: [
                Text(
                  isKhmer ? 'ទំនិញដែលត្រូវគ្នា' : 'Matching Products',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$_totalResults',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _searchResults.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: ResponsiveLayout.isTablet(context) ? 3 : 2,
                childAspectRatio:
                    ResponsiveLayout.productGridAspectRatio(context),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final product = _searchResults[index];
                return GroceryItemCardWidget(
                  item: product,
                  heroSuffix: "explore-${product.id}-$index",
                );
              },
            ),
            if (_isLoadingMore) ...[
              const SizedBox(height: 20),
              const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
          ] else if (matchingCategories.isEmpty)
            _buildEmptySearch(isKhmer),
        ],
      ),
    );
  }

  Widget _buildProductShimmerGrid(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveLayout.isTablet(context) ? 3 : 2,
        childAspectRatio: ResponsiveLayout.productGridAspectRatio(context),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 12,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 14,
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: 16,
                    width: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptySearch(bool isKhmer) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 40,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isKhmer
                  ? 'រកមិនឃើញលទ្ធផលសម្រាប់ "$query"'
                  : 'No results found for "$query"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isKhmer
                  ? 'សូមព្យាយាមស្វែងរកជាមួយពាក្យគន្លឹះផ្សេង'
                  : 'Try searching with different keywords or check spelling.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _clearSearch,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(isKhmer ? 'សម្អាតការស្វែងរក' : 'Clear Search'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(
    BuildContext context,
    List<CategoryModel> categories,
  ) {
    final crossAxisCount = ResponsiveLayout.isTablet(context) ? 3 : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: ResponsiveLayout.isTablet(context) ? 2.4 : 2.1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final category = categories[index];
        final categoryItem = CategoryItem(
          id: category.id,
          name: category.localizedName(context),
          imagePath: category.image,
        );

        return GestureDetector(
          onTap: () => onCategoryItemClicked(context, category),
          child: CategoryItemCardWidget(
            item: categoryItem,
            color: gridColors[index % gridColors.length],
          ),
        );
      },
    );
  }

  Widget _buildShimmerGrid(BuildContext context) {
    final crossAxisCount = ResponsiveLayout.isTablet(context) ? 3 : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 8,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: ResponsiveLayout.isTablet(context) ? 2.4 : 2.1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void onCategoryItemClicked(BuildContext context, CategoryModel category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return CategoryItemsScreen(
            categoryName: category.localizedName(context),
          );
        },
      ),
    );
  }
}
