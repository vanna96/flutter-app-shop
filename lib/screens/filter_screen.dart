import 'package:grocery_app/localization/localized_material.dart';
import 'package:get/get.dart';
import 'package:grocery_app/common_widgets/app_button.dart';
import 'package:grocery_app/controllers/category_controller.dart';
import 'package:grocery_app/controllers/language_controller.dart';
import 'package:grocery_app/data/mock_data.dart';
import 'package:grocery_app/helpers/category_visuals.dart';
import 'package:grocery_app/helpers/responsive_layout.dart';
import 'package:grocery_app/styles/colors.dart';

class FilterScreen extends StatefulWidget {
  const FilterScreen({
    super.key,
    this.initialCategories = const <String>{},
    this.initialSort,
  });

  final Set<String> initialCategories;
  final String? initialSort;

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  late Set<String> selectedCategories;
  late String? selectedSort;

  final List<Map<String, dynamic>> sortOptions = const [
    {
      "label": "Price: Low to High",
      "icon": Icons.arrow_upward_rounded,
    },
    {
      "label": "Price: High to Low",
      "icon": Icons.arrow_downward_rounded,
    },
    {
      "label": "Name: A-Z",
      "icon": Icons.sort_by_alpha_rounded,
    },
    {
      "label": "Name: Z-A",
      "icon": Icons.sort_by_alpha_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    selectedCategories = {...widget.initialCategories};
    selectedSort = widget.initialSort;

    if (Get.isRegistered<CategoryController>()) {
      final controller = Get.find<CategoryController>();
      if (controller.categories.isEmpty) {
        controller.fetchInitData();
      }
    }
  }

  void _resetFilters() {
    setState(() {
      selectedCategories.clear();
      selectedSort = null;
    });
  }

  void _applyFilters() {
    Navigator.pop(context, {
      'categories': selectedCategories.toList(growable: false),
      'sort': selectedSort,
    });
  }

  int get totalActiveFilters {
    return selectedCategories.length + (selectedSort != null ? 1 : 0);
  }

  @override
  Widget build(BuildContext context) {
    final CategoryController? categoryController =
        Get.isRegistered<CategoryController>()
            ? Get.find<CategoryController>()
            : null;
    final LanguageController? languageController =
        Get.isRegistered<LanguageController>()
            ? Get.find<LanguageController>()
            : null;
    final isKhmer = languageController?.currentLanguageCode.value == 'km';

    final horizontalPadding = ResponsiveLayout.horizontalPadding(context);
    final contentMaxWidth = ResponsiveLayout.maxContentWidth(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Center(
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Color(0xFF334155),
                size: 18,
              ),
            ),
          ),
        ),
        title: Text(
          isKhmer ? 'តម្រង & តម្រៀប' : 'Filter & Sort',
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          if (totalActiveFilters > 0)
            TextButton(
              onPressed: _resetFilters,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFF762D),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: Text(
                isKhmer ? 'កំណត់ឡើងវិញ' : 'Reset',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFF1F5F9),
            height: 1,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentMaxWidth),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              22,
              horizontalPadding,
              30,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Minimal Sort By Section
                _buildMinimalSectionTitle(
                  isKhmer ? 'តម្រៀបតាម' : 'SORT BY',
                  trailing: selectedSort != null
                      ? _buildCountBadge('1 selected')
                      : null,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: sortOptions.map((opt) {
                    final label = opt["label"] as String;
                    final icon = opt["icon"] as IconData;
                    final isSelected = selectedSort == label;

                    return InkWell(
                      onTap: () {
                        setState(() {
                          selectedSort = isSelected ? null : label;
                        });
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFFF7ED)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFFF762D)
                                : const Color(0xFFE2E8F0),
                            width: isSelected ? 1.4 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              icon,
                              size: 14,
                              color: isSelected
                                  ? const Color(0xFFFF762D)
                                  : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? const Color(0xFFEA580C)
                                    : const Color(0xFF334155),
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.check_rounded,
                                size: 14,
                                color: Color(0xFFFF762D),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 28),
                const Divider(color: Color(0xFFF1F5F9), height: 1),
                const SizedBox(height: 24),

                // 2. Minimal Categories Section
                _buildMinimalSectionTitle(
                  isKhmer ? 'ប្រភេទមុខទំនិញ' : 'CATEGORIES',
                  trailing: selectedCategories.isNotEmpty
                      ? _buildCountBadge('${selectedCategories.length} selected')
                      : null,
                ),
                const SizedBox(height: 14),

                Obx(() {
                  final catList = (categoryController != null &&
                          categoryController.categories.isNotEmpty)
                      ? categoryController.categories
                          .map((c) => c.name.trim())
                          .where((n) => n.isNotEmpty)
                          .toSet()
                          .toList()
                      : MockDataRepository.categories
                          .map((c) => c.name.trim())
                          .where((n) => n.isNotEmpty)
                          .toSet()
                          .toList();

                  if (categoryController != null &&
                      categoryController.isLoading.value &&
                      catList.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    );
                  }

                  if (catList.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        isKhmer
                            ? 'មិនមានប្រភេទមុខទំនិញទេ'
                            : 'No categories available',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                        ),
                      ),
                    );
                  }

                  return Wrap(
                    spacing: 8,
                    runSpacing: 9,
                    children: catList.map((category) {
                      final isSelected = selectedCategories.contains(category);
                      final icon = CategoryVisuals.getIcon(category);

                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              selectedCategories.remove(category);
                            } else {
                              selectedCategories.add(category);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFFFF7ED)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFFF762D)
                                  : const Color(0xFFE2E8F0),
                              width: isSelected ? 1.4 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                icon,
                                size: 14,
                                color: isSelected
                                    ? const Color(0xFFFF762D)
                                    : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                category,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? const Color(0xFFEA580C)
                                      : const Color(0xFF334155),
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 5),
                                const Icon(
                                  Icons.check_rounded,
                                  size: 14,
                                  color: Color(0xFFFF762D),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: Color(0xFFF1F5F9), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: AppButton(
            label: totalActiveFilters > 0
                ? (isKhmer
                    ? "អនុវត្តតម្រង ($totalActiveFilters)"
                    : "Apply Filters ($totalActiveFilters)")
                : (isKhmer ? "មើលទំនិញទាំងអស់" : "Show All Products"),
            fontWeight: FontWeight.bold,
            height: 50,
            onPressed: _applyFilters,
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalSectionTitle(String title, {Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: Color(0xFF64748B),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildCountBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFD8A8)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFEA580C),
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}
