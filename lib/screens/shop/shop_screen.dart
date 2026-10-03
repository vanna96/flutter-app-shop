import 'dart:async';
import 'package:grocery_app/localization/localized_material.dart';
import 'package:get/get.dart';
import 'package:grocery_app/controllers/language_controller.dart';
import 'package:grocery_app/controllers/product_controller.dart';
import 'package:grocery_app/controllers/store_controller.dart';
import 'package:grocery_app/data/mock_data.dart';
import 'package:grocery_app/helpers/responsive_layout.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/screens/product_details/product_details_screen.dart';
import 'package:grocery_app/services/mobile_api_repository.dart';
import 'package:grocery_app/styles/colors.dart';
import 'package:grocery_app/widgets/grocery_item_card_widget.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  _ShopScreenState createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final MobileApiRepository _apiRepository = MobileApiRepository();
  final ProductController productController = Get.find<ProductController>();
  final LanguageController languageController = Get.find<LanguageController>();
  final StoreController storeController = Get.find<StoreController>();

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Timer? _debounceTimer;
  Worker? _branchWorker;

  List<ProductModel> _products = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalProducts = 0;

  bool isGridView = true;
  String? selectedSort;
  String query = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    _fetchProducts(reset: true);

    _branchWorker = ever(storeController.selectedLocationId, (_) {
      _fetchProducts(reset: true);
    });
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
    _branchWorker?.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
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
        _products = [];
      });
    }

    final selectedBranchId = storeController.selectedLocationId.value;
    final branchIdParam = selectedBranchId > 0 ? selectedBranchId : null;
    final pageToFetch = reset ? 1 : _currentPage + 1;
    final searchKeyword = query.trim();

    try {
      final response = await _apiRepository.fetchProductsPaginated(
        page: pageToFetch,
        perPage: 20,
        sort: _mapSort(selectedSort),
        search: searchKeyword,
        branchId: branchIdParam,
      );

      MockDataRepository.updateProducts(response.items);

      if (mounted) {
        setState(() {
          if (reset) {
            _products = List<ProductModel>.from(response.items);
          } else {
            _products.addAll(response.items);
          }
          _currentPage = response.currentPage;
          _lastPage = response.lastPage;
          _totalProducts = response.total;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        if (reset && _products.isEmpty) {
          // Fallback to local products if offline
          var local = List<ProductModel>.from(productController.shopProducts);
          if (selectedBranchId > 0) {
            local = local.where((p) => p.branchId == selectedBranchId).toList();
          }
          if (searchKeyword.isNotEmpty) {
            final kw = searchKeyword.toLowerCase();
            local = local
                .where((p) =>
                    p.name.toLowerCase().contains(kw) ||
                    (p.khName?.toLowerCase().contains(kw) ?? false) ||
                    p.description.toLowerCase().contains(kw))
                .toList();
          }
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
            _products = local;
            _currentPage = 1;
            _lastPage = 1;
            _totalProducts = local.length;
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

  void _onSortChanged(String? val) {
    setState(() {
      selectedSort = val;
    });
    _fetchProducts(reset: true);
  }

  void _showSortBottomSheet(BuildContext context, bool isKhmer) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final options = [
          "Price: Low to High",
          "Price: High to Low",
          "Name: A-Z",
          "Name: Z-A",
        ];
        
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.sort_rounded, color: AppColors.primaryColor),
                      const SizedBox(width: 12),
                      Text(
                        isKhmer ? 'តម្រៀបតាម' : 'Sort By',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                ...options.map((option) {
                  final isSelected = selectedSort == option;
                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _onSortChanged(option);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              option,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? AppColors.primaryColor : const Color(0xFF334155),
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded, color: AppColors.primaryColor, size: 22),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
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
              isKhmer ? 'ទំនិញទាំងអស់' : 'All Products',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isKhmer
                  ? 'រុករក និងបញ្ជាទិញទំនិញស្រស់ៗ'
                  : 'Browse and order fresh store items',
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
          child: Column(
            children: [
              _buildViewToggleAndSortToolbar(horizontalPadding, isKhmer),
              Expanded(
                child: _isLoading
                    ? _buildShimmerList(horizontalPadding)
                    : _products.isEmpty
                        ? _buildEmptyState(isKhmer)
                        : _buildProductList(_products, horizontalPadding),
              ),
            ],
          ),
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
                    ? 'ស្វែងរកទំនិញ...'
                    : 'Search products by name...',
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

  Widget _buildViewToggleAndSortToolbar(
      double horizontalPadding, bool isKhmer) {
    return Container(
      margin: EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 8),
      child: Row(
        children: [
          // Sort Dropdown Pill
          // Sort Dropdown Pill (Redesigned as Bottom Sheet Trigger)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showSortBottomSheet(context, isKhmer),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 36,
                padding: const EdgeInsets.only(left: 14, right: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sort_rounded,
                        size: 16, color: AppColors.primaryColor),
                    const SizedBox(width: 6),
                    Text(
                      selectedSort ?? (isKhmer ? 'តម្រៀប' : 'Sort'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 18, color: Color(0xFF94A3B8)),
                  ],
                ),
              ),
            ),
          ),
          if (_totalProducts > 0) ...[
            const SizedBox(width: 8),
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
              ),
              child: Row(
                children: [
                  Text(
                    '$_totalProducts',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Items',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Spacer(),
          // View Toggle Buttons (List / Grid)
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isGridView = true;
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isGridView ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: isGridView
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      Icons.grid_view_rounded,
                      size: 18,
                      color: isGridView
                          ? AppColors.primaryColor
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isGridView = false;
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: !isGridView ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: !isGridView
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      Icons.view_agenda_rounded,
                      size: 18,
                      color: !isGridView
                          ? AppColors.primaryColor
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isKhmer) {
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
              query.isNotEmpty
                  ? (isKhmer
                      ? 'រកមិនឃើញទំនិញសម្រាប់ "$query"'
                      : 'No products found for "$query"')
                  : (isKhmer
                      ? 'មិនមានទំនិញទេ'
                      : 'No products available'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              query.isNotEmpty
                  ? (isKhmer
                      ? 'សូមព្យាយាមស្វែងរកជាមួយពាក្យគន្លឹះផ្សេង'
                      : 'Try searching with different keywords or clear the filter.')
                  : (isKhmer
                      ? 'ទំនិញនឹងបង្ហាញនៅពេលមានក្នុងស្តុក'
                      : 'Products will appear here when added to stock.'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
            if (query.isNotEmpty || selectedSort != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    query = '';
                    selectedSort = null;
                  });
                  _fetchProducts(reset: true);
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(isKhmer ? 'កំណត់ឡើងវិញ' : 'Reset Filters'),
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
          ],
        ),
      ),
    );
  }

  Widget _buildProductList(
      List<ProductModel> items, double horizontalPadding) {
    return RefreshIndicator(
      color: AppColors.primaryColor,
      onRefresh: () => _fetchProducts(reset: true),
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 8,
            ),
            sliver: isGridView
                ? SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: ResponsiveLayout.gridColumns(
                        context,
                        minTileWidth: 190,
                      ),
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio:
                          ResponsiveLayout.productGridAspectRatio(context),
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final heroSuffix =
                            'shop-grid-${items[index].id}-$index';
                        return GestureDetector(
                          onTap: () => _onItemClicked(
                              context, items[index], heroSuffix),
                          child: GroceryItemCardWidget(
                            item: items[index],
                            heroSuffix: heroSuffix,
                          ),
                        );
                      },
                      childCount: items.length,
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final heroSuffix = 'shop-${items[index].id}-$index';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: GestureDetector(
                            onTap: () => _onItemClicked(
                                context, items[index], heroSuffix),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: ResponsiveLayout.isTablet(context)
                                      ? 720
                                      : double.infinity,
                                ),
                                child: GroceryItemCardWidget(
                                  item: items[index],
                                  heroSuffix: heroSuffix,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: items.length,
                    ),
                  ),
          ),
          if (_isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.primaryColor,
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
    );
  }

  Widget _buildShimmerList(double horizontalPadding) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
      child: GridView.builder(
        shrinkWrap: true,
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
        builder: (context) => ProductDetailsScreen(
          groceryItem,
          heroSuffix: heroSuffix,
        ),
      ),
    );
  }
}
