import 'dart:async';
import 'package:grocery_app/localization/localized_material.dart';
import 'package:grocery_app/localization/app_ui_translations.dart';
import 'package:get/get.dart';
import 'package:grocery_app/controllers/category_controller.dart';
import 'package:grocery_app/controllers/product_controller.dart';
import 'package:grocery_app/controllers/store_controller.dart';
import 'package:grocery_app/data/mock_data.dart';
import 'package:grocery_app/helpers/responsive_layout.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/screens/product_details/product_details_screen.dart';
import 'package:grocery_app/services/mobile_api_repository.dart';
import 'package:grocery_app/controllers/network_status_controller.dart';
import 'package:grocery_app/widgets/grocery_item_card_widget.dart';
import 'package:grocery_app/widgets/no_internet_widget.dart';

import 'filter_screen.dart';

class CategoryItemsScreen extends StatefulWidget {
  const CategoryItemsScreen({
    super.key,
    required this.categoryName,
  });

  final String categoryName;

  @override
  State<CategoryItemsScreen> createState() => _CategoryItemsScreenState();
}

class _CategoryItemsScreenState extends State<CategoryItemsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final MobileApiRepository _apiRepository = MobileApiRepository();
  final ProductController productController = Get.find<ProductController>();
  final StoreController storeController = Get.find<StoreController>();

  Timer? _debounceTimer;
  late Set<String> selectedCategories;
  String? selectedSort;
  String query = '';

  List<ProductModel> _items = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    selectedCategories = {widget.categoryName};
    _scrollController.addListener(_onScroll);
    _fetchProducts(reset: true);
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 250) {
      if (!_isLoadingMore && !_isLoading && _currentPage < _lastPage) {
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

  int? get _resolvedCategoryId {
    if (selectedCategories.length != 1) return null;
    final name = selectedCategories.first.toLowerCase();
    if (Get.isRegistered<CategoryController>()) {
      for (final cat in Get.find<CategoryController>().categories) {
        if (cat.name.toLowerCase() == name ||
            (cat.khName != null && cat.khName!.toLowerCase() == name)) {
          return cat.id;
        }
      }
    }
    return null;
  }

  String _mapSort(String? sort) {
    switch (sort) {
      case "Price: Low to High":
        return 'price_asc';
      case "Price: High to Low":
        return 'price_desc';
      case "Name: A-Z":
        return 'name_asc';
      case "Name: Z-A":
        return 'name_desc';
      default:
        return 'latest';
    }
  }

  Future<void> _fetchProducts({bool reset = true}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _items = [];
      });
    }

    final selectedBranchId = storeController.selectedLocationId.value;
    final branchIdParam = selectedBranchId > 0 ? selectedBranchId : null;
    final categoryIdParam = _resolvedCategoryId;
    final pageToFetch = reset ? 1 : _currentPage + 1;
    final searchKeyword = query.trim();

    try {
      final response = await _apiRepository.fetchProductsPaginated(
        page: pageToFetch,
        perPage: 20,
        categoryId: categoryIdParam,
        branchId: branchIdParam,
        search: searchKeyword,
        sort: _mapSort(selectedSort),
      );

      MockDataRepository.updateProducts(response.items);

      if (mounted) {
        setState(() {
          if (reset) {
            _items = List<ProductModel>.from(response.items);
          } else {
            _items.addAll(response.items);
          }
          _currentPage = response.currentPage;
          _lastPage = response.lastPage;
          _totalCount = response.total;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        if (reset && _items.isEmpty) {
          final keyword = query.trim().toLowerCase();
          var local = productController.shopProducts.where((product) {
            if (selectedBranchId > 0 && product.branchId != selectedBranchId) {
              return false;
            }
            final matchesCategory = selectedCategories.isEmpty ||
                selectedCategories.contains(product.categoryEn) ||
                selectedCategories.contains(product.categoryKh);
            final matchesSearch = keyword.isEmpty ||
                product.name.toLowerCase().contains(keyword) ||
                (product.khName?.toLowerCase().contains(keyword) ?? false) ||
                product.description.toLowerCase().contains(keyword);

            return matchesCategory && matchesSearch;
          }).toList();

          switch (selectedSort) {
            case "Price: Low to High":
              local.sort((a, b) => a.price.compareTo(b.price));
              break;
            case "Price: High to Low":
              local.sort((a, b) => b.price.compareTo(a.price));
              break;
            case "Name: A-Z":
              local.sort((a, b) => a.name.compareTo(b.name));
              break;
            case "Name: Z-A":
              local.sort((a, b) => b.name.compareTo(a.name));
              break;
          }

          setState(() {
            _items = local;
            _currentPage = 1;
            _lastPage = 1;
            _totalCount = local.length;
            _isLoading = false;
            _isLoadingMore = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _isLoadingMore = false;
          });
        }
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _isLoading || _currentPage >= _lastPage) {
      return;
    }
    setState(() {
      _isLoadingMore = true;
    });
    await _fetchProducts(reset: false);
  }

  void _onSearchChanged(String val) {
    _debounceTimer?.cancel();
    setState(() {
      query = val;
    });
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _fetchProducts(reset: true);
    });
  }

  void _onSearchSubmitted(String val) {
    _debounceTimer?.cancel();
    setState(() {
      query = val;
    });
    _fetchProducts(reset: true);
  }

  void _clearSearch() {
    _debounceTimer?.cancel();
    _searchController.clear();
    setState(() {
      query = '';
    });
    _fetchProducts(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveLayout.horizontalPadding(context);
    final contentMaxWidth = ResponsiveLayout.maxContentWidth(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Curved Warm Gradient Header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF762D), Color(0xFFFF8E42)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x28FF762D),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  10,
                  horizontalPadding,
                  16,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  widget.categoryName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    letterSpacing: -0.3,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_totalCount > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$_totalCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FilterScreen(
                                  initialCategories: selectedCategories,
                                  initialSort: selectedSort,
                                ),
                              ),
                            );

                            if (result is Map<String, dynamic>) {
                              setState(() {
                                final categories =
                                    result['categories'] as List<dynamic>? ?? [];
                                selectedCategories = categories
                                    .map((category) => category.toString())
                                    .toSet();
                                selectedSort = result['sort']?.toString();
                              });
                              _fetchProducts(reset: true);
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.tune,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              if (selectedSort != null)
                                Positioned(
                                  top: -2,
                                  right: -2,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Embedded search bar
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.search,
                            color: Color(0xFF94A3B8),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              textInputAction: TextInputAction.search,
                              onChanged: _onSearchChanged,
                              onSubmitted: _onSearchSubmitted,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1E293B),
                              ),
                              decoration: InputDecoration(
                                hintText: AppUiTranslations.text(
                                  context,
                                  'Search in ${widget.categoryName}...',
                                ),
                                hintStyle: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          if (query.isNotEmpty)
                            InkWell(
                              onTap: _clearSearch,
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Body Content
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentMaxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (selectedCategories.length > 1 || selectedSort != null)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          10,
                          horizontalPadding,
                          2,
                        ),
                        child: Row(
                          children: [
                            if (selectedSort != null)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF7ED),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFFFD8A8),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.sort,
                                      size: 13,
                                      color: Color(0xFFEA580C),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      selectedSort!,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFEA580C),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          selectedSort = null;
                                        });
                                        _fetchProducts(reset: true);
                                      },
                                      child: const Icon(
                                        Icons.close,
                                        size: 13,
                                        color: Color(0xFFEA580C),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ...selectedCategories.map((category) {
                              return Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      category,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                    if (selectedCategories.length > 1) ...[
                                      const SizedBox(width: 4),
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            selectedCategories.remove(category);
                                          });
                                          _fetchProducts(reset: true);
                                        },
                                        child: const Icon(
                                          Icons.close,
                                          size: 13,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    Expanded(
                      child: _isLoading
                          ? _buildShimmerGrid(horizontalPadding)
                          : _items.isEmpty
                              ? _buildEmptyState()
                              : RefreshIndicator(
                                  color: const Color(0xFFFF762D),
                                  onRefresh: () => _fetchProducts(reset: true),
                                  child: CustomScrollView(
                                    controller: _scrollController,
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    slivers: [
                                      SliverPadding(
                                        padding: EdgeInsets.all(
                                            horizontalPadding * 0.6),
                                        sliver: SliverGrid(
                                          gridDelegate:
                                              SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount:
                                                ResponsiveLayout.gridColumns(
                                              context,
                                              minTileWidth: 190,
                                            ),
                                            crossAxisSpacing: 14,
                                            mainAxisSpacing: 14,
                                            childAspectRatio:
                                                ResponsiveLayout
                                                    .productGridAspectRatio(
                                              context,
                                            ),
                                          ),
                                          delegate: SliverChildBuilderDelegate(
                                            (context, index) {
                                              final groceryItem = _items[index];
                                              final heroSuffix =
                                                  'category-${groceryItem.id}-$index';

                                              return GestureDetector(
                                                onTap: () {
                                                  onItemClicked(context,
                                                      groceryItem, heroSuffix);
                                                },
                                                child: GroceryItemCardWidget(
                                                  item: groceryItem,
                                                  heroSuffix: heroSuffix,
                                                ),
                                              );
                                            },
                                            childCount: _items.length,
                                          ),
                                        ),
                                      ),
                                      if (_isLoadingMore)
                                        const SliverToBoxAdapter(
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 20),
                                            child: Center(
                                              child: SizedBox(
                                                width: 24,
                                                height: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  color: Color(0xFFFF762D),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      const SliverToBoxAdapter(
                                        child: SizedBox(height: 24),
                                      ),
                                    ],
                                  ),
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerGrid(double horizontalPadding) {
    return GridView.builder(
      padding: EdgeInsets.all(horizontalPadding * 0.6),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveLayout.gridColumns(
          context,
          minTileWidth: 190,
        ),
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: ResponsiveLayout.productGridAspectRatio(context),
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
                      color: const Color(0xFFFF762D).withValues(alpha: 0.15),
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

  Widget _buildEmptyState() {
    if (Get.isRegistered<NetworkStatusController>() &&
        Get.find<NetworkStatusController>().isUnavailable.value) {
      return NoInternetWidget(
        onRetry: () => _fetchProducts(reset: true),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 40,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No products found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try adjusting your search or category filter.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 42,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF762D),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    query = '';
                    _searchController.clear();
                    selectedCategories = {widget.categoryName};
                    selectedSort = null;
                  });
                  _fetchProducts(reset: true);
                },
                child: const Text(
                  'Reset Filters',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onItemClicked(
    BuildContext context,
    ProductModel groceryItem,
    String heroSuffix,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsScreen(
          groceryItem,
          heroSuffix: heroSuffix,
        ),
      ),
    );
  }
}
