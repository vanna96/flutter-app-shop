import 'package:grocery_app/localization/localized_material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:grocery_app/controllers/language_controller.dart';
import 'package:grocery_app/screens/dashboard/dashboard_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final bool isFromSettings;

  const OnboardingScreen({super.key, this.isFromSettings = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final GetStorage _storage = GetStorage();
  int _currentPage = 0;

  final List<_OnboardingSlideData> _slides = const [
    _OnboardingSlideData(
      imagePath: 'assets/images/onboard_fresh_grocery.jpg',
      titleEn: 'Farm-Fresh Groceries',
      titleKm: 'ទំនិញស្រស់ៗពីកសិដ្ឋាន',
      subtitleEn:
          'Handpicked organic vegetables, seasonal fruits, and premium groceries delivered to your door.',
      subtitleKm:
          'បន្លែ និងផ្លែឈើធម្មជាតិស្រស់ៗ គុណភាពខ្ពស់ ដឹកជញ្ជូនដល់មុខផ្ទះរបស់អ្នកយ៉ាងឆាប់រហ័ស។',
      accentColor: Color(0xFFFF762D),
    ),
    _OnboardingSlideData(
      imagePath: 'assets/images/onboard_fast_delivery.jpg',
      titleEn: 'Superfast Delivery',
      titleKm: 'ដឹកជញ្ជូនរហ័សទាន់ចិត្ត',
      subtitleEn:
          'Real-time order tracking with fast courier express delivery right when you need it most.',
      subtitleKm:
          'តាមដានការដឹកជញ្ជូនជាក់ស្តែង ជាមួយសេវាដឹកជញ្ជូនរហ័សទាន់ចិត្ត គ្រប់ពេលវេលា។',
      accentColor: Color(0xFF8B5CF6),
    ),
    _OnboardingSlideData(
      imagePath: 'assets/images/onboard_smart_pay.jpg',
      titleEn: 'Smart POS & Checkout',
      titleKm: 'ការទូទាត់ឆ្លាតវៃ និងងាយស្រួល',
      subtitleEn:
          'Seamless payments in USD (\$) and Khmer Riel (៛), exclusive promo deals, and instant receipts.',
      subtitleKm:
          'ទូទាត់ប្រាក់យ៉ាងងាយស្រួលទាំងប្រាក់ដុល្លារ (\$) និងប្រាក់រៀល (៛) ជាមួយការបញ្ចុះតម្លៃពិសេស។',
      accentColor: Color(0xFF0D9488),
    ),
  ];

  void _onNextTap() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() {
    _storage.write('has_seen_onboarding', true);

    if (widget.isFromSettings) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const DashboardScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageController = Get.find<LanguageController>();
    final isKhmer = languageController.currentLanguageCode.value == 'km';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Full-Height Image Slider
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              final slide = _slides[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    slide.imagePath,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                  // Dark gradient overlay for text readability
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.0, 0.35, 0.65, 1.0],
                        colors: [
                          Color(0x66000000),
                          Color(0x00000000),
                          Color(0x99000000),
                          Color(0xF5000000),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // 2. Top Bar (Logo & Skip Button)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // App Brand Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFFF762D),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'V-POS GROCERY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Skip Button
                  InkWell(
                    onTap: _finishOnboarding,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        isKhmer ? 'រំលង' : 'SKIP',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Bottom Content & Navigation
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 26),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Slide Title
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      child: Text(
                        isKhmer
                            ? _slides[_currentPage].titleKm
                            : _slides[_currentPage].titleEn,
                        key: ValueKey('title_$_currentPage'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          height: 1.15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Slide Subtitle
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      child: Text(
                        isKhmer
                            ? _slides[_currentPage].subtitleKm
                            : _slides[_currentPage].subtitleEn,
                        key: ValueKey('sub_$_currentPage'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Bottom Navigation Bar: Dots (Left) + Action (Right)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Animated Page Indicator Dots
                        Row(
                          children: List.generate(_slides.length, (index) {
                            final isActive = index == _currentPage;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 260),
                              margin: const EdgeInsets.only(right: 7),
                              width: isActive ? 28 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        ),

                        // Action Button (NEXT ↗ or GET STARTED ↗)
                        InkWell(
                          onTap: _onNextTap,
                          borderRadius: BorderRadius.circular(24),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 260),
                            padding: EdgeInsets.symmetric(
                              horizontal: _currentPage == _slides.length - 1
                                  ? 22
                                  : 16,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: _currentPage == _slides.length - 1
                                  ? const Color(0xFFFF762D)
                                  : Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: _currentPage == _slides.length - 1
                                    ? const Color(0xFFFF8E42)
                                    : Colors.white.withValues(alpha: 0.35),
                                width: 1.2,
                              ),
                              boxShadow: _currentPage == _slides.length - 1
                                  ? [
                                      const BoxShadow(
                                        color: Color(0x66FF762D),
                                        blurRadius: 16,
                                        offset: Offset(0, 6),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _currentPage == _slides.length - 1
                                      ? (isKhmer ? 'ចាប់ផ្តើម' : 'GET STARTED')
                                      : (isKhmer ? 'បន្ទាប់' : 'NEXT'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.north_east_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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
}

class _OnboardingSlideData {
  final String imagePath;
  final String titleEn;
  final String titleKm;
  final String subtitleEn;
  final String subtitleKm;
  final Color accentColor;

  const _OnboardingSlideData({
    required this.imagePath,
    required this.titleEn,
    required this.titleKm,
    required this.subtitleEn,
    required this.subtitleKm,
    required this.accentColor,
  });
}
