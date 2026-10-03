import 'package:grocery_app/localization/localized_material.dart';
import 'package:get/get.dart';
import 'package:grocery_app/common_widgets/app_button.dart';
import 'package:grocery_app/controllers/app_state_controller.dart';
import 'package:grocery_app/common_widgets/app_text.dart';
import 'package:grocery_app/controllers/app_config_controller.dart';
import 'package:grocery_app/controllers/banner_controller.dart';
import 'package:grocery_app/controllers/category_controller.dart';
import 'package:grocery_app/controllers/notification_controller.dart';
import 'package:grocery_app/controllers/product_controller.dart';
import 'package:grocery_app/controllers/store_controller.dart';
import 'package:grocery_app/controllers/network_status_controller.dart';
import 'package:grocery_app/services/api_service.dart';
import 'package:grocery_app/styles/colors.dart';

class DeveloperSettingsScreen extends StatefulWidget {
  const DeveloperSettingsScreen({super.key});

  @override
  State<DeveloperSettingsScreen> createState() =>
      _DeveloperSettingsScreenState();
}

class _DeveloperSettingsScreenState extends State<DeveloperSettingsScreen> {
  final AppConfigController appConfigController =
      Get.find<AppConfigController>();

  late final TextEditingController baseApiUrlController;
  late final TextEditingController apiPathController;
  late final TextEditingController tenantController;

  bool isSaving = false;
  bool isTesting = false;
  ConnectionTestResult? testResult;

  @override
  void initState() {
    super.initState();
    baseApiUrlController =
        TextEditingController(text: appConfigController.baseApiUrl.value);
    apiPathController =
        TextEditingController(text: appConfigController.apiPath.value);
    tenantController =
        TextEditingController(text: appConfigController.tenant.value);

    baseApiUrlController.addListener(_onFieldChanged);
    apiPathController.addListener(_onFieldChanged);
    tenantController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (testResult != null) {
      testResult = null;
    }
    setState(() {});
  }

  @override
  void dispose() {
    baseApiUrlController.removeListener(_onFieldChanged);
    apiPathController.removeListener(_onFieldChanged);
    tenantController.removeListener(_onFieldChanged);
    baseApiUrlController.dispose();
    apiPathController.dispose();
    tenantController.dispose();
    super.dispose();
  }

  String get _effectivePreviewUrl {
    final raw = baseApiUrlController.text.trim();
    if (raw.isEmpty) {
      return '(Not configured)';
    }
    final sanitized = AppConfigController.sanitizeBaseUrl(raw);
    if (sanitized.isEmpty) {
      return '(Not configured)';
    }
    return ApiService.normalizeBaseUrl(
      sanitized,
      apiPath: apiPathController.text,
    );
  }

  String get _effectiveTenant {
    return tenantController.text.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAF8),
      appBar: AppBar(
        title: const Text(
          'Developer Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPreviewCard(),
            const SizedBox(height: 16),
            _buildFormCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'LIVE RESOLVED ENDPOINT',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SelectableText(
            _effectivePreviewUrl,
            style: const TextStyle(
              color: Color(0xFF38BDF8),
              fontFamily: 'Courier',
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_effectiveTenant.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Text(
                  'Tenant Header: ',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
                Text(
                  _effectiveTenant,
                  style: const TextStyle(
                    color: Color(0xFFFBBF24),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText(
            text: 'Configure Connection',
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 8),
          Obx(
            () {
              final active = appConfigController.baseApiUrl.value.trim();
              final tenant = appConfigController.tenant.value.trim();
              final text = active.isEmpty
                  ? 'Active: None (Offline / Mock data)'
                  : 'Active: $active ${tenant.isEmpty ? "" : "• " + tenant}';
              return AppText(
                text: text,
                fontSize: 13,
                color: Colors.grey,
                maxLines: 4,
              );
            },
          ),
          const SizedBox(height: 16),
          _buildField(
            label: 'Base API URL or Domain',
            controller: baseApiUrlController,
            icon: Icons.link,
            hint: 'e.g. https://vanna-pos.duckdns.org or http://localhost:8880',
            keyboardType: TextInputType.url,
          ),
          _buildField(
            label: 'API Path / Prefix',
            controller: apiPathController,
            icon: Icons.alt_route_rounded,
            hint: 'e.g. /v1/api or /v2/api',
          ),
          _buildField(
            label: 'Tenant',
            controller: tenantController,
            icon: Icons.apartment_outlined,
            hint: 'e.g. rechna',
          ),
          const SizedBox(height: 6),
          // Test Connection button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: (isSaving || isTesting) ? null : _testConnection,
              icon: isTesting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryColor,
                      ),
                    )
                  : const Icon(
                      Icons.network_check_rounded,
                      color: AppColors.primaryColor,
                    ),
              label: Text(
                isTesting ? 'Testing Connection...' : 'Test Connection',
                style: const TextStyle(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                  color: AppColors.primaryColor,
                  width: 1.5,
                ),
                backgroundColor: AppColors.primaryLight.withValues(alpha: 0.45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          if (testResult != null) ...[
            const SizedBox(height: 12),
            _buildTestResultCard(testResult!),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: (isSaving || isTesting) ? null : _reset,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: BorderSide(color: Colors.grey.shade300),
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Reset',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: AppButton(
                  label: isSaving ? 'Saving...' : 'Save Settings',
                  height: 54,
                  onPressed: (isSaving || isTesting) ? null : _save,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestResultCard(ConnectionTestResult result) {
    final isSuccess = result.isSuccess;
    final bgColor =
        isSuccess ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2);
    final borderColor =
        isSuccess ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5);
    final iconColor =
        isSuccess ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final titleColor =
        isSuccess ? const Color(0xFF15803D) : const Color(0xFFB91C1C);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isSuccess
                    ? Icons.check_circle_rounded
                    : Icons.error_outline_rounded,
                color: iconColor,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.message,
                      style: TextStyle(
                        color: titleColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Latency: ${result.latencyMs} ms • Status: ${result.statusCode > 0 ? result.statusCode : 'Failed'}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (result.details != null && result.details!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              result.details!,
              style: TextStyle(
                color: isSuccess
                    ? const Color(0xFF166534)
                    : const Color(0xFF991B1B),
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            'Target: ${result.testedUrl}',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
              fontFamily: 'Courier',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testConnection() async {
    final url = baseApiUrlController.text.trim();
    final tenant = tenantController.text.trim();

    if (url.isEmpty) {
      Get.snackbar(
        'Missing URL',
        'Please enter a Base API URL to test.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (tenant.isEmpty) {
      Get.snackbar(
        'Missing Tenant',
        'Please enter a Tenant name.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      isTesting = true;
      testResult = null;
    });

    final res = await ApiService.testConnection(
      rawUrl: url,
      tenant: tenant,
      apiPath: apiPathController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      isTesting = false;
      testResult = res;
    });
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: const Color(0xffF5F7F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: AppColors.primaryColor,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final inputUrl = baseApiUrlController.text.trim();
    final tenant = tenantController.text.trim();

    if (inputUrl.isNotEmpty && tenant.isEmpty) {
      Get.snackbar(
        'Missing Tenant',
        'Please enter a Tenant name.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final cleanUrl = AppConfigController.sanitizeBaseUrl(inputUrl);
      final apiPath = apiPathController.text.trim();

      await appConfigController.updateConfig(
        baseApiUrlValue: cleanUrl,
        tenantValue: tenant,
        apiPathValue: apiPath,
      );
      ApiService().refreshConfig();

      if (cleanUrl != inputUrl) {
        baseApiUrlController.text = cleanUrl;
      }

      await _refreshAppData();

      if (Get.isRegistered<NetworkStatusController>()) {
        Get.find<NetworkStatusController>().markAvailable();
      }

      if (!mounted) {
        return;
      }

      final active = appConfigController.baseApiUrl.value.trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            active.isEmpty
                ? 'API configuration cleared (Using mock data)'
                : 'Connected to $active (Tenant: $tenant)',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.primaryColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Settings saved with warning: ${e.toString().split('\n').first}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Future<void> _reset() async {
    setState(() {
      isSaving = true;
      testResult = null;
    });

    try {
      await appConfigController.reset();
      ApiService().refreshConfig();
      baseApiUrlController.text = appConfigController.baseApiUrl.value;
      apiPathController.text = appConfigController.apiPath.value;
      tenantController.text = appConfigController.tenant.value;
      await _refreshAppData();

      if (!mounted) return;

      Get.snackbar(
        'Settings reset',
        'Developer API settings were restored to defaults.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
      );
    } catch (e) {
      if (!mounted) return;
      Get.snackbar(
        'Reset notice',
        'Restored to defaults, sync warning: ${e.toString().split('\n').first}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Future<void> _refreshAppData() async {
    final futures = <Future<void>>[];

    if (Get.isRegistered<StoreController>()) {
      futures.add(Get.find<StoreController>().fetchInitData());
    }
    if (Get.isRegistered<BannerController>()) {
      futures.add(Get.find<BannerController>().fetchInitData());
    }
    if (Get.isRegistered<CategoryController>()) {
      futures.add(Get.find<CategoryController>().fetchInitData());
    }
    if (Get.isRegistered<ProductController>()) {
      futures.add(Get.find<ProductController>().fetchInitData());
    }
    if (Get.isRegistered<NotificationController>()) {
      futures.add(Get.find<NotificationController>().fetchInitData());
    }
    if (Get.isRegistered<AppStateController>()) {
      futures.add(Get.find<AppStateController>().syncRemoteState());
    }

    if (futures.isEmpty) {
      return;
    }

    await Future.wait(futures);
  }
}
