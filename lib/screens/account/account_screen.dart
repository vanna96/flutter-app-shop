import 'package:grocery_app/localization/localized_material.dart';
import 'package:get/get.dart';
import 'package:grocery_app/common_widgets/app_button.dart';
import 'package:grocery_app/controllers/app_state_controller.dart';
import 'package:grocery_app/controllers/language_controller.dart';
import 'package:grocery_app/controllers/login_controller.dart';
import 'package:grocery_app/controllers/navigation_controller.dart';
import 'package:grocery_app/controllers/notification_controller.dart';
import 'package:grocery_app/generated/l10n.dart';
import 'package:grocery_app/helpers/responsive_layout.dart';
import 'package:grocery_app/screens/account/address_list_screen.dart';
import 'package:grocery_app/screens/account/developer_settings_screen.dart';
import 'package:grocery_app/screens/account/order_history_screen.dart';
import 'package:grocery_app/screens/account/profile_screen.dart';
import 'package:grocery_app/screens/account/translate_page.dart';
import 'package:grocery_app/screens/favourite_screen.dart';
import 'package:grocery_app/screens/home/notification_list_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:grocery_app/screens/onboarding_screen.dart';
import 'package:grocery_app/screens/account/legal_screen.dart';
import 'package:grocery_app/widgets/app_network_image.dart';

class AccountScreen extends StatelessWidget {
  final LanguageController languageController = Get.find<LanguageController>();
  final LoginController loginController = Get.find<LoginController>();
  final NotificationController notificationController = Get.put(
    NotificationController(),
  );
  final AppStateController appStateController = Get.find<AppStateController>();

  AccountScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Obx(() {
        return loginController.isAuthenticated.value
            ? _buildAccountPage(context)
            : _buildLoginPage(context);
      }),
    );
  }

  // ==========================================
  // 1. AUTHENTICATED ACCOUNT PAGE
  // ==========================================
  Widget _buildAccountPage(BuildContext context) {
    final horizontalPadding = ResponsiveLayout.horizontalPadding(context);
    final contentMaxWidth = ResponsiveLayout.maxContentWidth(context);
    final topPadding = MediaQuery.of(context).padding.top;
    // Leave enough room for all three profile text lines. The previous 96px
    // body was exactly the avatar height plus padding, which could overflow on
    // iOS because its text metrics make the details column slightly taller.
    final headerHeight = topPadding + 104.0;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Pinned Curved Warm Gradient Top Banner with Profile Header
        SliverPersistentHeader(
          pinned: true,
          delegate: _PinnedProfileHeaderDelegate(
            height: headerHeight,
            child: _buildProfileHeader(context, horizontalPadding),
          ),
        ),

        // Main Settings Area (Max Width on Large Screens)
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentMaxWidth),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  16,
                  horizontalPadding,
                  30,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Stats Row (Orders, Favorites, Cart)
                    _buildQuickStatsRow(context),

                    const SizedBox(height: 22),

                    // Section 1: Shopping & Orders
                    _buildSectionTitle('SHOPPING & ORDERS'),
                    const SizedBox(height: 8),
                    _buildGroupedCard([
                      _SettingsTile(
                        icon: Icons.receipt_long_outlined,
                        iconColor: const Color(0xFFEA580C),
                        iconBg: const Color(0xFFFFF7ED),
                        title: 'Orders',
                        subtitle: 'Track past purchases & receipts',
                        trailingBadge: Obx(() {
                          final count = appStateController.orderHistory.length;
                          return count > 0
                              ? _buildCountBadge('$count')
                              : const SizedBox.shrink();
                        }),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const OrderHistoryScreen(),
                          ),
                        ),
                      ),
                      _buildDivider(),
                      _SettingsTile(
                        icon: Icons.location_on_outlined,
                        iconColor: const Color(0xFF2563EB),
                        iconBg: const Color(0xFFEFF6FF),
                        title: 'Delivery Addresses',
                        subtitle: 'Saved delivery destinations',
                        trailingBadge: Obx(() {
                          final count = loginController.addresses.length;
                          return count > 0
                              ? _buildCountBadge('$count')
                              : const SizedBox.shrink();
                        }),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddressListScreen(),
                          ),
                        ),
                      ),
                      _buildDivider(),
                      _SettingsTile(
                        icon: Icons.favorite_border_rounded,
                        iconColor: const Color(0xFFE11D48),
                        iconBg: const Color(0xFFFFF1F2),
                        title: 'My Favorites',
                        subtitle: 'Products you saved for later',
                        trailingBadge: Obx(() {
                          final count =
                              appStateController.favoriteProducts.length;
                          return count > 0
                              ? _buildCountBadge('$count')
                              : const SizedBox.shrink();
                        }),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => FavouriteScreen()),
                        ),
                      ),
                    ]),

                    const SizedBox(height: 22),

                    // Section 2: Preferences
                    _buildSectionTitle('PREFERENCES'),
                    const SizedBox(height: 8),
                    _buildGroupedCard([
                      _SettingsTile(
                        icon: Icons.language_rounded,
                        iconColor: const Color(0xFF9333EA),
                        iconBg: const Color(0xFFFAF5FF),
                        title: 'Language',
                        subtitle: 'Display and receipt language',
                        trailingBadge: Obx(
                          () => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E8FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              languageController.currentLanguage.value,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF9333EA),
                              ),
                            ),
                          ),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => TranslatePage()),
                        ),
                      ),
                      _buildDivider(),
                      _SettingsTile(
                        icon: Icons.notifications_none_rounded,
                        iconColor: const Color(0xFF059669),
                        iconBg: const Color(0xFFECFDF5),
                        title: 'Notifications',
                        subtitle: 'Order updates and promos',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NotificationListScreen(),
                          ),
                        ),
                      ),
                    ]),

                    const SizedBox(height: 22),

                    // Section 3: Support & System
                    _buildSectionTitle('SUPPORT & SYSTEM'),
                    const SizedBox(height: 8),
                    _buildGroupedCard([
                      _SettingsTile(
                        icon: Icons.auto_awesome_rounded,
                        iconColor: const Color(0xFFFF762D),
                        iconBg: const Color(0xFFFFF7ED),
                        title: 'App Tour & Guide',
                        subtitle: 'View features and walkthrough guide',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const OnboardingScreen(isFromSettings: true),
                          ),
                        ),
                      ),
                      _buildDivider(),
                      _SettingsTile(
                        icon: Icons.help_outline_rounded,
                        iconColor: const Color(0xFF0284C7),
                        iconBg: const Color(0xFFF0F9FF),
                        title: 'Help & FAQ',
                        subtitle: 'Customer assistance and guide',
                        onTap: () => _showHelpBottomSheet(context),
                      ),
                      _buildDivider(),
                      _SettingsTile(
                        icon: Icons.description_outlined,
                        iconColor: const Color(0xFF10B981),
                        iconBg: const Color(0xFFD1FAE5),
                        title: 'Terms & Conditions',
                        subtitle: 'Read our terms of service',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LegalScreen(
                              documentType: 'terms_conditions',
                              title: 'Terms & Conditions',
                            ),
                          ),
                        ),
                      ),
                      _buildDivider(),
                      _SettingsTile(
                        icon: Icons.shield_outlined,
                        iconColor: const Color(0xFF6366F1),
                        iconBg: const Color(0xFFE0E7FF),
                        title: 'Privacy Policy',
                        subtitle: 'How we handle your data',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LegalScreen(
                              documentType: 'privacy_policy',
                              title: 'Privacy Policy',
                            ),
                          ),
                        ),
                      ),
                      _buildDivider(),
                      _SettingsTile(
                        icon: Icons.info_outline_rounded,
                        iconColor: const Color(0xFF475569),
                        iconBg: const Color(0xFFF1F5F9),
                        title: 'About V-POS',
                        subtitle: 'Version 1.0.0 (Production POS)',
                        onTap: () => showAboutDialog(
                          context: context,
                          applicationName: 'V-POS Grocery',
                          applicationVersion: '1.0.0',
                          children: const [
                            Text(
                              'Multi-currency grocery and retail point-of-sale platform.',
                            ),
                          ],
                        ),
                      ),
                      _buildDivider(),
                      _SettingsTile(
                        icon: Icons.tune_rounded,
                        iconColor: const Color(0xFF64748B),
                        iconBg: const Color(0xFFF8FAFC),
                        title: 'Server & Tenant Settings',
                        subtitle: 'Local backend, ports and branch ID',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DeveloperSettingsScreen(),
                          ),
                        ),
                      ),
                    ]),

                    const SizedBox(height: 24),

                    // Log Out Button
                    _buildLogoutButton(),

                    const SizedBox(height: 20),

                    Center(
                      child: Text(
                        'V-POS Grocery App v1.0.0 • Connected to Local Host',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // PROFILE TOP BANNER
  // ==========================================
  Widget _buildProfileHeader(BuildContext context, double horizontalPadding) {
    return Container(
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
            12,
            horizontalPadding,
            20,
          ),
          child: Obx(() {
            final dynamic userData = loginController.userData.value;
            final profileImageUrl =
                userData?['profile_image_url']?.toString() ?? '';

            return Row(
              children: [
                // Avatar with white ring
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: profileImageUrl.trim().isNotEmpty
                        ? AppNetworkImage(
                            image: profileImageUrl,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            fallbackIcon: Icons.person,
                          )
                        : Image.asset(
                            "assets/images/profile.png",
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                const SizedBox(width: 14),

                // Name and Email
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loginController.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        userData?['email'] ?? 'vpos.member@retail.kh',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        userData?['phone'] ?? '+855 12 345 678',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Edit Profile Action Chip
                InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.edit, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Edit',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // ==========================================
  // QUICK STATS ROW
  // ==========================================
  Widget _buildQuickStatsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Obx(
            () => _QuickStatTile(
              label: 'Orders',
              count: '${appStateController.orderHistory.length}',
              icon: Icons.receipt_long_outlined,
              iconColor: const Color(0xFFEA580C),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Obx(
            () => _QuickStatTile(
              label: 'Favorites',
              count: '${appStateController.favoriteProducts.length}',
              icon: Icons.favorite_outline_rounded,
              iconColor: const Color(0xFFE11D48),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FavouriteScreen()),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Obx(
            () => _QuickStatTile(
              label: 'In Cart',
              count: '${appStateController.cartItemCount}',
              icon: Icons.shopping_bag_outlined,
              iconColor: const Color(0xFF0284C7),
              onTap: () {
                try {
                  final nav = Get.find<NavigationController>();
                  nav.currentIndex.value = 3; // Cart tab
                } catch (_) {}
              },
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // GROUPED SETTINGS CARDS HELPERS
  // ==========================================
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: Color(0xFF94A3B8),
        ),
      ),
    );
  }

  Widget _buildGroupedCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 54,
      endIndent: 16,
      color: Color(0xFFF1F5F9),
    );
  }

  Widget _buildCountBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF475569),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return InkWell(
      onTap: () async {
        await loginController.logout();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 18),
            SizedBox(width: 8),
            Text(
              'Log Out',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFDC2626),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.help_outline_rounded,
                    color: Color(0xFFFF762D),
                    size: 24,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Help & Guidance',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                '• Home: Highlights, banners, and curated product sections.\n'
                '• Explore: Search by category with high-res photos and icons.\n'
                '• Shop: Full product catalog with real-time currency pricing.\n'
                '• Cart: Automatic promotions (e.g. SPEND200 15% OFF) and payment.\n'
                '• Account: Member profile, order history, addresses, and language.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF475569),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF762D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // 2. MODERN LOGIN PAGE
  // ==========================================
  Widget _buildLoginPage(BuildContext context) {
    final horizontalPadding = ResponsiveLayout.horizontalPadding(context);
    final contentMaxWidth = ResponsiveLayout.maxContentWidth(context);

    return SingleChildScrollView(
      child: Column(
        children: [
          // Top Curved Header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF762D), Color(0xFFFF8E42)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
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
                  12,
                  horizontalPadding,
                  30,
                ),
                child: Column(
                  children: [
                    // Language selector at top right
                    Align(
                      alignment: Alignment.topRight,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TranslatePage(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.language,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 5),
                              Obx(
                                () => Text(
                                  languageController.currentLanguage.value,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Avatar/Logo
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.8),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: SvgPicture.asset(
                          'assets/icons/v_pos_mark.svg',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text(
                      S.of(context).welcome_back,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      S.of(context).please_login,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Login Form Body
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentMaxWidth),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  24,
                  horizontalPadding,
                  40,
                ),
                child: Column(
                  children: [
                    // Email field
                    TextFormField(
                      controller: loginController.emailTextController,
                      onChanged: (v) {
                        loginController.email.value = v;
                        if (loginController.errorMessage.value.isNotEmpty) {
                          loginController.errorMessage.value = '';
                        }
                      },
                      decoration: InputDecoration(
                        hintText: S.of(context).email_username,
                        prefixIcon: const Icon(
                          Icons.person_outline,
                          color: Color(0xFF64748B),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 18,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFFF762D),
                            width: 2,
                          ),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    // Password field
                    Obx(() {
                      final isVisible = loginController.isPasswordVisible.value;
                      return TextFormField(
                        controller: loginController.passwordTextController,
                        onChanged: (v) {
                          loginController.password.value = v;
                          if (loginController.errorMessage.value.isNotEmpty) {
                            loginController.errorMessage.value = '';
                          }
                        },
                        obscureText: !isVisible,
                        decoration: InputDecoration(
                          hintText: S.of(context).password,
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: Color(0xFF64748B),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              isVisible
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: const Color(0xFF94A3B8),
                              size: 20,
                            ),
                            onPressed: () =>
                                loginController.isPasswordVisible.toggle(),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 18,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFFF762D),
                              width: 2,
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 10),

                    Obx(
                      () => InkWell(
                        onTap: () => loginController.setRememberMe(
                          !loginController.rememberMe.value,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: loginController.rememberMe.value,
                                  onChanged: (value) => loginController
                                      .setRememberMe(value ?? false),
                                  activeColor: const Color(0xFFFF762D),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  side: const BorderSide(
                                    color: Color(0xFFCBD5E1),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Remember me',
                                style: TextStyle(
                                  color: Color(0xFF475569),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      'Use your POS operator or demo credentials to sign in.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Sign In Button
                    Obx(() {
                      return loginController.isLoading.value
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFFF762D),
                              ),
                            )
                          : AppButton(
                              height: 56,
                              label: S.of(context).login,
                              fontWeight: FontWeight.bold,
                              onPressed: () async {
                                FocusScope.of(context).unfocus();
                                bool success = await loginController.login();
                                if (success) {
                                  ScaffoldMessenger.of(
                                    context,
                                  ).hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      elevation: 0,
                                      backgroundColor: Colors.transparent,
                                      behavior: SnackBarBehavior.floating,
                                      margin: const EdgeInsets.fromLTRB(
                                        16,
                                        0,
                                        16,
                                        20,
                                      ),
                                      padding: EdgeInsets.zero,
                                      duration: const Duration(seconds: 3),
                                      content: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0F172A),
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                          border: Border.all(
                                            color: const Color(
                                              0xFF10B981,
                                            ).withValues(alpha: 0.35),
                                            width: 1.2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF0F172A,
                                              ).withValues(alpha: 0.35),
                                              blurRadius: 24,
                                              offset: const Offset(0, 10),
                                            ),
                                            BoxShadow(
                                              color: const Color(
                                                0xFF10B981,
                                              ).withValues(alpha: 0.15),
                                              blurRadius: 12,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFF10B981,
                                                ).withValues(alpha: 0.18),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Center(
                                                child: Icon(
                                                  Icons
                                                      .check_circle_outline_rounded,
                                                  color: Color(0xFF34D399),
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            const Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    "Login Successful",
                                                    style: TextStyle(
                                                      fontSize: 13.5,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.white,
                                                      letterSpacing: 0.1,
                                                    ),
                                                  ),
                                                  SizedBox(height: 3),
                                                  Text(
                                                    "Welcome back to your account.",
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      color: Color(0xFF94A3B8),
                                                      height: 1.25,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                } else {
                                  final errorText =
                                      loginController
                                          .errorMessage
                                          .value
                                          .isNotEmpty
                                      ? loginController.errorMessage.value
                                      : "Invalid username or password.";

                                  ScaffoldMessenger.of(
                                    context,
                                  ).hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      elevation: 0,
                                      backgroundColor: Colors.transparent,
                                      behavior: SnackBarBehavior.floating,
                                      margin: const EdgeInsets.fromLTRB(
                                        16,
                                        0,
                                        16,
                                        20,
                                      ),
                                      padding: EdgeInsets.zero,
                                      duration: const Duration(seconds: 4),
                                      content: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0F172A),
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                          border: Border.all(
                                            color: const Color(
                                              0xFFEF4444,
                                            ).withValues(alpha: 0.35),
                                            width: 1.2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF0F172A,
                                              ).withValues(alpha: 0.35),
                                              blurRadius: 24,
                                              offset: const Offset(0, 10),
                                            ),
                                            BoxShadow(
                                              color: const Color(
                                                0xFFEF4444,
                                              ).withValues(alpha: 0.15),
                                              blurRadius: 12,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFFEF4444,
                                                ).withValues(alpha: 0.18),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Center(
                                                child: Icon(
                                                  Icons.error_outline_rounded,
                                                  color: Color(0xFFF87171),
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Text(
                                                    "Authentication Failed",
                                                    style: TextStyle(
                                                      fontSize: 13.5,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.white,
                                                      letterSpacing: 0.1,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    errorText,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      color: Color(0xFF94A3B8),
                                                      height: 1.25,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            GestureDetector(
                                              onTap: () {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).hideCurrentSnackBar();
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.08),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.close_rounded,
                                                  color: Color(0xFF94A3B8),
                                                  size: 15,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              },
                            );
                    }),
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

// ==========================================
// PRIVATE SUB-WIDGETS
// ==========================================

class _QuickStatTile extends StatelessWidget {
  const _QuickStatTile({
    required this.label,
    required this.count,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  final String label;
  final String count;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: iconColor),
              const SizedBox(height: 6),
              Text(
                count,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    this.trailingBadge,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final Widget? trailingBadge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (trailingBadge != null) ...[
                trailingBadge!,
                const SizedBox(width: 8),
              ],
              const Icon(
                Icons.arrow_forward_ios,
                size: 13,
                color: Color(0xFFCBD5E1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinnedProfileHeaderDelegate extends SliverPersistentHeaderDelegate {
  _PinnedProfileHeaderDelegate({required this.child, required this.height});

  final Widget child;
  final double height;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _PinnedProfileHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}
