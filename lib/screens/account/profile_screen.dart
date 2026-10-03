import 'dart:convert';
import 'dart:io';

import 'package:grocery_app/localization/localized_material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:grocery_app/common_widgets/app_button.dart';
import 'package:grocery_app/common_widgets/app_text.dart';
import 'package:grocery_app/controllers/login_controller.dart';
import 'package:grocery_app/styles/colors.dart';
import 'package:grocery_app/widgets/app_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const MethodChannel _iosProfileImagePickerChannel =
      MethodChannel('grocery_app/profile_image_picker');

  final LoginController loginController = Get.find<LoginController>();

  static const List<String> genderOptions = [
    'Female',
    'Male',
    'Other',
  ];

  static const List<String> countryCodes = [
    '+855',
    '+66',
    '+84',
    '+65',
    '+1',
  ];

  late final TextEditingController nameController;
  late final TextEditingController firstNameController;
  late final TextEditingController lastNameController;
  late final TextEditingController usernameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;
  late final TextEditingController passwordController;
  late final TextEditingController dobController;

  late String selectedGender;
  late String selectedCountryCode;

  File? selectedProfileImageFile;
  String? selectedProfileImageBase64;

  bool isSaving = false;
  bool obscurePassword = true;

  @override
  void initState() {
    super.initState();
    final user = loginController.currentUser;
    final customer = user['customer'] as Map<String, dynamic>?;

    var firstName = (customer?['first_name']?.toString().trim() ?? '')
        .ifEmpty(user['first_name']?.toString().trim() ?? '');
    var lastName = (customer?['last_name']?.toString().trim() ?? '')
        .ifEmpty(user['last_name']?.toString().trim() ?? '');
    final fullName = (user['full_name']?.toString().trim() ?? '')
        .ifEmpty(user['name']?.toString().trim() ?? '$firstName $lastName'.trim());

    if (firstName.isEmpty && lastName.isEmpty && fullName.isNotEmpty) {
      final parts = fullName.split(' ');
      firstName = parts.first;
      if (parts.length > 1) {
        lastName = parts.sublist(1).join(' ');
      }
    }

    nameController = TextEditingController(text: fullName);
    firstNameController = TextEditingController(text: firstName);
    lastNameController = TextEditingController(text: lastName);
    usernameController =
        TextEditingController(text: user['username']?.toString() ?? '');
    emailController =
        TextEditingController(text: user['email']?.toString() ?? '');
    phoneController =
        TextEditingController(text: user['phone']?.toString() ?? '');
    passwordController =
        TextEditingController(text: user['password']?.toString() ?? '');
    dobController = TextEditingController(text: user['dob']?.toString() ?? '');

    selectedGender = user['gender']?.toString() ?? genderOptions.first;
    if (!genderOptions.contains(selectedGender)) {
      selectedGender = genderOptions.first;
    }

    var userCountry = user['country_code']?.toString().trim() ?? '';
    if (userCountry.isNotEmpty && !userCountry.startsWith('+')) {
      userCountry = '+$userCountry';
    }
    selectedCountryCode = countryCodes.contains(userCountry)
        ? userCountry
        : countryCodes.first;
  }

  @override
  void dispose() {
    nameController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    dobController.dispose();
    super.dispose();
  }

  String get previewName {
    if (nameController.text.trim().isNotEmpty) {
      return nameController.text.trim();
    }

    return '${firstNameController.text.trim()} ${lastNameController.text.trim()}'
        .trim()
        .ifEmpty('Demo Shopper');
  }

  String get profileImageUrl =>
      loginController.currentUser['profile_image_url']?.toString() ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAF8),
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroCard(),
            const SizedBox(height: 22),
            _buildFormCard(
              title: 'Identity',
              children: [
                _buildField(
                  label: 'Name',
                  controller: nameController,
                  icon: Icons.badge_outlined,
                  onChanged: (_) => setState(() {}),
                ),
                _buildResponsiveTwoFields(
                  first: _buildField(
                    label: 'First Name',
                    controller: firstNameController,
                    icon: Icons.person_outline,
                    onChanged: (_) => setState(() {}),
                  ),
                  second: _buildField(
                    label: 'Last Name',
                    controller: lastNameController,
                    icon: Icons.person_outline,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                _buildField(
                  label: 'Username',
                  controller: usernameController,
                  icon: Icons.alternate_email,
                ),
                _buildDropdownField(
                  label: 'Gender',
                  icon: Icons.wc,
                  value: selectedGender,
                  items: genderOptions,
                  onChanged: (value) {
                    setState(() {
                      selectedGender = value!;
                    });
                  },
                ),
                _buildField(
                  label: 'DOB',
                  controller: dobController,
                  icon: Icons.cake_outlined,
                  readOnly: true,
                  onTap: _pickDateOfBirth,
                ),
              ],
            ),
            const SizedBox(height: 18),
            _buildFormCard(
              title: 'Contact',
              children: [
                _buildField(
                  label: 'Email',
                  controller: emailController,
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) => setState(() {}),
                ),
                _buildResponsiveTwoFields(
                  first: _buildDropdownField(
                    label: 'Code',
                    icon: Icons.flag_outlined,
                    value: selectedCountryCode,
                    items: countryCodes,
                    onChanged: (value) {
                      setState(() {
                        selectedCountryCode = value!;
                      });
                    },
                  ),
                  second: _buildField(
                    label: 'Phone',
                    controller: phoneController,
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  firstFlex: 2,
                  secondFlex: 3,
                ),
                _buildField(
                  label: 'Password',
                  controller: passwordController,
                  icon: Icons.lock_outline,
                  obscureText: obscurePassword,
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                    icon: Icon(
                      obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            AppButton(
              label: isSaving ? 'Saving...' : 'Save Profile',
              onPressed: isSaving ? null : _saveProfile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              _buildProfileAvatar(radius: 34),
              Positioned(
                right: -4,
                bottom: -4,
                child: GestureDetector(
                  onTap: _pickProfileImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      size: 18,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  text: previewName,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  maxLines: 2,
                ),
                const SizedBox(height: 4),
                AppText(
                  text: emailController.text,
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.88),
                  maxLines: 2,
                ),
                const SizedBox(height: 6),
                AppText(
                  text: '$selectedCountryCode ${phoneController.text}'.trim(),
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.82),
                  maxLines: 1,
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _pickProfileImage,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.28),
                      ),
                    ),
                    child: const Text(
                      'Upload Profile Photo',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
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

  Widget _buildProfileAvatar({required double radius}) {
    if (selectedProfileImageFile != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white.withValues(alpha: 0.25),
        backgroundImage: FileImage(selectedProfileImageFile!),
      );
    }

    if (profileImageUrl.trim().isNotEmpty) {
      return Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.25),
        ),
        clipBehavior: Clip.antiAlias,
        child: AppNetworkImage(
          image: profileImageUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          fallbackIcon: Icons.person,
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white.withValues(alpha: 0.25),
      child: Icon(Icons.person, color: Colors.white, size: radius),
    );
  }

  Widget _buildFormCard({
    required String title,
    required List<Widget> children,
  }) {
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
          AppText(
            text: title,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool readOnly = false,
    Widget? suffixIcon,
    VoidCallback? onTap,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        readOnly: readOnly,
        onTap: onTap,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: suffixIcon,
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

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        onChanged: onChanged,
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
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildResponsiveTwoFields({
    required Widget first,
    required Widget second,
    int firstFlex = 1,
    int secondFlex = 1,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 360) {
          return Column(
            children: [
              first,
              second,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: firstFlex, child: first),
            const SizedBox(width: 12),
            Expanded(flex: secondFlex, child: second),
          ],
        );
      },
    );
  }

  Future<void> _pickDateOfBirth() async {
    DateTime initialDate;
    try {
      initialDate = DateTime.parse(dobController.text);
    } catch (_) {
      initialDate = DateTime(1998, 1, 1);
    }

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950, 1, 1),
      lastDate: DateTime.now(),
    );

    if (selected != null) {
      dobController.text = DateFormat('yyyy-MM-dd').format(selected);
      setState(() {});
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      XFile? pickedFile;

      // 1. Primary: Use ImagePicker with compression to keep payload small (< 150KB)
      try {
        final picker = ImagePicker();
        pickedFile = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 80,
          maxWidth: 800,
          maxHeight: 800,
          requestFullMetadata: false,
        );
      } catch (pickerError) {
        // 2. Fallback on iOS if image_picker native plugin is missing from running runner
        if (Platform.isIOS) {
          try {
            final pickedPath = await _iosProfileImagePickerChannel
                .invokeMethod<String>('pickImage');
            if (pickedPath != null && pickedPath.trim().isNotEmpty) {
              pickedFile = XFile(pickedPath);
            }
          } catch (_) {
            rethrow;
          }
        } else {
          rethrow;
        }
      }

      if (pickedFile == null) {
        return;
      }

      final bytes = await pickedFile.readAsBytes();
      final extension = pickedFile.name.split('.').last.toLowerCase();
      String mimeType;
      if (extension == 'jpg' || extension == 'jpeg') {
        mimeType = 'jpeg';
      } else if (extension == 'webp') {
        mimeType = 'webp';
      } else {
        mimeType = 'png';
      }

      setState(() {
        selectedProfileImageFile = File(pickedFile!.path);
        selectedProfileImageBase64 =
            'data:image/$mimeType;base64,${base64Encode(bytes)}';
      });

      Get.snackbar(
        'Photo selected',
        'Tap Save Profile to save your new photo.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primaryColor,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (error) {
      Get.snackbar(
        'Image picker error',
        error.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  Future<void> _saveProfile() async {
    final username = usernameController.text.trim();
    if (username.isEmpty) {
      Get.snackbar(
        'Missing Username',
        'Username is required to identify your account.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final name = nameController.text.trim();
    final first = firstNameController.text.trim();
    final last = lastNameController.text.trim();
    if (name.isEmpty && first.isEmpty && last.isEmpty) {
      Get.snackbar(
        'Missing Name',
        'Please enter your name.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final pwd = passwordController.text.trim();
    if (pwd.isNotEmpty && pwd.length < 6) {
      Get.snackbar(
        'Invalid Password',
        'Password must be at least 6 characters long.',
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
      await loginController.updateProfile(
        name: name,
        firstName: first,
        lastName: last,
        username: username,
        email: emailController.text.trim(),
        gender: selectedGender,
        countryCode: selectedCountryCode,
        phone: phoneController.text.trim(),
        password: pwd.isNotEmpty ? pwd : null,
        profileBase64: selectedProfileImageBase64,
        dob: dobController.text.trim(),
      );

      if (mounted) {
        setState(() {
          isSaving = false;
          selectedProfileImageBase64 = null;
        });
      }

      Get.snackbar(
        'Profile updated',
        'Your profile information has been saved successfully.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primaryColor,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }

      final errorMsg = loginController.extractErrorMessage(e);
      Get.snackbar(
        'Update Failed',
        errorMsg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }
}

extension on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}
