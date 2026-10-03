import 'package:grocery_app/localization/localized_material.dart';
import 'package:grocery_app/localization/app_ui_translations.dart';
import 'package:get/get.dart';
import 'package:grocery_app/common_widgets/app_button.dart';
import 'package:grocery_app/common_widgets/app_text.dart';
import 'package:grocery_app/controllers/login_controller.dart';
import 'package:grocery_app/styles/colors.dart';

class AddressListScreen extends StatefulWidget {
  const AddressListScreen({super.key});

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  final LoginController loginController = Get.find<LoginController>();

  static const List<String> countryCodes = [
    '+855',
    '+66',
    '+84',
    '+65',
    '+1',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAF8),
      appBar: AppBar(
        title: const Text(
          'My Addresses',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        final addresses = loginController.addresses;
        return SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroCard(addresses),
                      const SizedBox(height: 22),
                      if (addresses.isEmpty)
                        _buildEmptyState()
                      else ...[
                        ...addresses.map(
                          (address) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _buildAddressCard(address),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: AppButton(
                  label: 'Add New Address',
                  onPressed: _showAddAddressSheet,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHeroCard(List<Map<String, dynamic>> addresses) {
    final defaultAddress = loginController.defaultAddress;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withValues(alpha: 0.78),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on_outlined, color: Colors.white),
              SizedBox(width: 10),
              AppText(
                text: 'Delivery Address Book',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppText(
            text:
                '${addresses.length} saved address${addresses.length == 1 ? '' : 'es'}',
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.9),
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          AppText(
            text: defaultAddress == null
                ? 'Add your first delivery address so checkout can use it later.'
                : 'Default: ${defaultAddress['label']} • ${defaultAddress['city']}',
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.86),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: const [
          Icon(
            Icons.location_off_outlined,
            size: 44,
            color: Colors.grey,
          ),
          SizedBox(height: 12),
          AppText(
            text: 'No addresses yet',
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          SizedBox(height: 8),
          AppText(
            text:
                'Create a delivery address to preview how the account flow looks.',
            textAlign: TextAlign.center,
            color: Colors.grey,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(Map<String, dynamic> address) {
    final bool isDefault = address['is_default'] == true;
    final note = address['note']?.toString().trim() ?? '';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      text: address['label']?.toString() ?? 'Address',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      text: address['recipient_name']?.toString() ?? '',
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              if (isDefault)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Default',
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _buildInfoRow(
            icon: Icons.phone_outlined,
            text: '${address['country_code'] ?? ''} ${address['phone'] ?? ''}'
                .trim(),
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            icon: Icons.location_on_outlined,
            text: '${address['line_1'] ?? ''}, ${address['city'] ?? ''}'.trim(),
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildInfoRow(
              icon: Icons.sticky_note_2_outlined,
              text: note,
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (!isDefault)
                OutlinedButton.icon(
                  onPressed: () => loginController
                      .setDefaultAddress(address['id'].toString()),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Set Default'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryColor,
                    side: const BorderSide(color: AppColors.primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: () => _showEditAddressSheet(address),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _confirmDeleteAddress(address),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 18, color: Colors.grey.shade700),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: AppText(
            text: text,
            fontSize: 14,
            color: Colors.grey.shade800,
            maxLines: 4,
          ),
        ),
      ],
    );
  }

  Future<void> _showAddAddressSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _AddressFormSheet(
          countryCodes: countryCodes,
          fallbackRecipientName:
              loginController.displayName.ifEmpty('Demo Shopper'),
          fallbackCountryCode:
              loginController.currentUser['country_code']?.toString() ?? '+855',
          fallbackPhone: loginController.currentUser['phone']?.toString() ?? '',
          onSave: ({
            required String label,
            required String recipientName,
            required String countryCode,
            required String phone,
            required String line1,
            required String city,
            required String note,
            required bool isDefault,
          }) async {
            await loginController.addAddress(
              label: label,
              recipientName: recipientName,
              countryCode: countryCode,
              phone: phone,
              line1: line1,
              city: city,
              note: note,
              isDefault: isDefault,
            );
          },
        );
      },
    );
  }

  Future<void> _showEditAddressSheet(Map<String, dynamic> address) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _AddressFormSheet(
          countryCodes: countryCodes,
          initialAddress: address,
          fallbackRecipientName:
              loginController.displayName.ifEmpty('Demo Shopper'),
          fallbackCountryCode:
              loginController.currentUser['country_code']?.toString() ?? '+855',
          fallbackPhone: loginController.currentUser['phone']?.toString() ?? '',
          onSave: ({
            required String label,
            required String recipientName,
            required String countryCode,
            required String phone,
            required String line1,
            required String city,
            required String note,
            required bool isDefault,
          }) async {
            await loginController.updateAddress(
              id: address['id'].toString(),
              label: label,
              recipientName: recipientName,
              countryCode: countryCode,
              phone: phone,
              line1: line1,
              city: city,
              note: note,
              isDefault: isDefault,
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteAddress(Map<String, dynamic> address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Delete Address'),
          content: Text(
            'Remove ${address['label']} from your saved delivery addresses?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await loginController.deleteAddress(address['id'].toString());
      Get.snackbar(
        'Address removed',
        '${address['label']} was deleted from your local account data.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
      );
    }
  }
}

typedef AddressFormSave = Future<void> Function({
  required String label,
  required String recipientName,
  required String countryCode,
  required String phone,
  required String line1,
  required String city,
  required String note,
  required bool isDefault,
});

class _AddressFormSheet extends StatefulWidget {
  const _AddressFormSheet({
    required this.countryCodes,
    required this.fallbackRecipientName,
    required this.fallbackCountryCode,
    required this.fallbackPhone,
    required this.onSave,
    this.initialAddress,
  });

  final List<String> countryCodes;
  final String fallbackRecipientName;
  final String fallbackCountryCode;
  final String fallbackPhone;
  final Map<String, dynamic>? initialAddress;
  final AddressFormSave onSave;

  @override
  State<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<_AddressFormSheet> {
  late final TextEditingController labelController;
  late final TextEditingController recipientController;
  late final TextEditingController phoneController;
  late final TextEditingController line1Controller;
  late final TextEditingController cityController;
  late final TextEditingController noteController;

  late String selectedCountryCode;
  late bool isDefault;
  bool isSaving = false;

  bool get isEditing => widget.initialAddress != null;

  @override
  void initState() {
    super.initState();
    final address = widget.initialAddress;
    labelController =
        TextEditingController(text: address?['label']?.toString() ?? '');
    recipientController = TextEditingController(
      text: address?['recipient_name']?.toString() ??
          widget.fallbackRecipientName,
    );
    phoneController = TextEditingController(
      text: address?['phone']?.toString() ?? widget.fallbackPhone,
    );
    line1Controller =
        TextEditingController(text: address?['line_1']?.toString() ?? '');
    cityController = TextEditingController(
        text: address?['city']?.toString() ?? 'Phnom Penh');
    noteController =
        TextEditingController(text: address?['note']?.toString() ?? '');

    selectedCountryCode =
        address?['country_code']?.toString() ?? widget.fallbackCountryCode;
    if (!widget.countryCodes.contains(selectedCountryCode)) {
      selectedCountryCode = widget.countryCodes.first;
    }

    isDefault = address?['is_default'] == true;
  }

  @override
  void dispose() {
    labelController.dispose();
    recipientController.dispose();
    phoneController.dispose();
    line1Controller.dispose();
    cityController.dispose();
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 12, 12, bottomInset + 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        isEditing ? 'Edit Address' : 'Add New Address',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap:
                          isSaving ? null : () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Save delivery details locally so the account UI is ready before real API integration.',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                _buildField(
                  label: 'Label',
                  controller: labelController,
                  icon: Icons.bookmark_border,
                ),
                _buildField(
                  label: 'Recipient Name',
                  controller: recipientController,
                  icon: Icons.person_outline,
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 360) {
                      return Column(
                        children: [
                          _buildDropdownField(),
                          _buildField(
                            label: 'Phone',
                            controller: phoneController,
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildDropdownField(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: _buildField(
                            label: 'Phone',
                            controller: phoneController,
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                _buildField(
                  label: 'Address Line',
                  controller: line1Controller,
                  icon: Icons.location_on_outlined,
                ),
                _buildField(
                  label: 'City',
                  controller: cityController,
                  icon: Icons.location_city_outlined,
                ),
                _buildField(
                  label: 'Note',
                  controller: noteController,
                  icon: Icons.sticky_note_2_outlined,
                  maxLines: 3,
                ),
                SwitchListTile.adaptive(
                  value: isDefault,
                  onChanged: (value) {
                    setState(() {
                      isDefault = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppColors.primaryColor,
                  title: const Text(
                    'Set as default address',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: OutlinedButton(
                          onPressed: isSaving
                              ? null
                              : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: AppButton(
                        height: 56,
                        padding: EdgeInsets.zero,
                        label: isSaving
                            ? (isEditing ? 'Saving...' : 'Adding...')
                            : (isEditing ? 'Save Address' : 'Add Address'),
                        onPressed: isSaving ? null : _submit,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
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

  Widget _buildDropdownField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        initialValue: selectedCountryCode,
        onChanged: (value) {
          if (value == null) {
            return;
          }

          setState(() {
            selectedCountryCode = value;
          });
        },
        decoration: InputDecoration(
          labelText: AppUiTranslations.text(context, 'Code'),
          prefixIcon: const Icon(Icons.flag_outlined),
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
        items: widget.countryCodes.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _submit() async {
    if (labelController.text.trim().isEmpty ||
        recipientController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        line1Controller.text.trim().isEmpty ||
        cityController.text.trim().isEmpty) {
      Get.snackbar(
        'Missing info',
        'Please complete label, recipient name, phone, address line, and city.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    await widget.onSave(
      label: labelController.text,
      recipientName: recipientController.text,
      countryCode: selectedCountryCode,
      phone: phoneController.text,
      line1: line1Controller.text,
      city: cityController.text,
      note: noteController.text,
      isDefault: isDefault,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      isSaving = false;
    });

    Get.back();
    Get.snackbar(
      isEditing ? 'Address updated' : 'Address added',
      isEditing
          ? 'Your delivery address was updated locally.'
          : 'A new delivery address was added locally.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primaryColor,
      colorText: Colors.white,
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}
