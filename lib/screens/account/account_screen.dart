import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:demo_app/common_widgets/app_text.dart';
import 'package:demo_app/controllers/language_controller.dart';
import 'package:demo_app/controllers/login_controller.dart';
import 'package:demo_app/controllers/notification_controller.dart';
import 'package:demo_app/helpers/column_with_seprator.dart';
import 'package:demo_app/screens/account/translate_page.dart';
import 'package:demo_app/styles/colors.dart';
import 'account_item.dart';
import 'package:demo_app/common_widgets/app_button.dart';
import 'package:demo_app/generated/l10n.dart';

class AccountScreen extends StatelessWidget {

  final LanguageController languageController = Get.find<LanguageController>();
  final LoginController loginController = Get.find<LoginController>();
  final NotificationController notificationController =
  Get.put(NotificationController());

  AccountScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Obx(() {
          return loginController.isAuthenticated.value
              ? _buildAccountPage(context)
              : _buildLoginPage(context);
        }),
      ),
    );
  }

  Widget _buildLoginPage(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Language selector at the top right
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TranslatePage(),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.language, color: Colors.black),
                        const SizedBox(width: 5),
                        Obx(() => Text(
                              languageController.currentLanguage.value,
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            )),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 10),

                // Profile avatar
                CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage("assets/images/profile.png"),
                  backgroundColor: AppColors.primaryColor.withOpacity(0.7),
                ),
                SizedBox(height: 30),

                AppText(
                  text: S.of(context).welcome_back,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
                SizedBox(height: 10),
                AppText(
                  text: S.of(context).please_login,
                  fontSize: 16,
                  color: Colors.grey,
                ),
                SizedBox(height: 30),

                // Email field
                TextFormField(
                  onChanged: (v) => loginController.email.value = v,
                  decoration: InputDecoration(
                    hintText: S.of(context).email_username,
                    prefixIcon: Icon(Icons.people_sharp),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide:
                          BorderSide(color: Colors.grey.shade400, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide:
                          BorderSide(color: Colors.grey.shade400, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: Colors.blue, width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),

                SizedBox(height: 20),

                // Password field
                TextFormField(
                  onChanged: (v) => loginController.password.value = v,
                  decoration: InputDecoration(
                    hintText: S.of(context).password,
                    prefixIcon: Icon(Icons.lock),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide:
                          BorderSide(color: Colors.grey.shade400, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide:
                          BorderSide(color: Colors.grey.shade400, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: Colors.blue, width: 2),
                    ),
                  ),
                  obscureText: true,
                ),

                SizedBox(height: 20),

                // Login button
                Obx(() {
                  return loginController.isLoading.value
                      ? CircularProgressIndicator()
                      : AppButton(
                          height: 60,
                          label: S.of(context).login,
                          fontWeight: FontWeight.w600,
                          padding: EdgeInsets.symmetric(vertical: 10),
                          onPressed: () async {
                            bool success = await loginController.login();
                            if (success) {
                              Get.snackbar(
                                "Success",
                                "Login successful!",
                                snackPosition: SnackPosition.BOTTOM,
                                duration: Duration(seconds: 3),
                                backgroundColor: AppColors.primaryColor,
                                colorText: Colors.white,
                              );


                              // Update after 2 seconds
                              Future.delayed(Duration(seconds: 3), () {
                                loginController.isAuthenticated.value = true;
                              });
                            }
                          },
                        );
                }),

                SizedBox(height: 15),
              ],
            ),
          ),
        );
      },
    );
  }

// Helper for social buttons
  Widget _socialLoginButton(String iconPath) {
    return InkWell(
      onTap: () {
        // Social login logic
      },
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: SvgPicture.asset(
          iconPath,
          width: 24,
          height: 24,
        ),
      ),
    );
  }

  Widget _buildAccountPage(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height - 150,
      ),
      child: IntrinsicHeight(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 20),
            Obx(() {
              final dynamic userData = loginController.userData.value;
              return ListTile(
                leading: SizedBox(width: 65, height: 65, child: getImageHeader()),
                title: AppText(
                  text: "${userData['customer']['first_name']} ${userData['customer']['last_name']}",
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                subtitle: AppText(
                  text: userData['email'] ?? '@',
                  color: Color(0xff7C7C7C),
                  fontWeight: FontWeight.normal,
                  fontSize: 16,
                  overflow: TextOverflow.ellipsis, // show "..." if too long
                ),
              );
            }),
            // Account items
            ...getChildrenWithSeperator(
              widgets:
                  accountItems.map((e) => getAccountItemWidget(e)).toList(),
              seperator: Divider(
                thickness: 1,
                color: Color(0x379E9E97),
              ),
            ),
            Spacer(), // pushes logout button to bottom
            logoutButton(),
            SizedBox(height: 15), // bottom spacing
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 10),
              child: Text(
                'Version 0.0.1',
                style: TextStyle(
                  color: Colors.grey, // optional styling
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget logoutButton() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 25),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.0),
          ),
          elevation: 0,
          backgroundColor: Color(0xffF2F3F2),
          padding: EdgeInsets.symmetric(vertical: 24, horizontal: 25),
          minimumSize: const Size.fromHeight(50),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: SvgPicture.asset(
                "assets/icons/account_icons/logout_icon.svg",
              ),
            ),
            Text(
              "Log Out",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
            Container() // empty to balance row
          ],
        ),
        onPressed: () {
          // Clear storage
          loginController.box.remove("user");
          loginController.userData.value = {};
          loginController.isAuthenticated.value = false;
          notificationController.notifications.value = [];
        },
      ),
    );
  }

  Widget getImageHeader() {
    String imagePath = "assets/images/profile.png";
    return CircleAvatar(
      radius: 32.5, // original ~65/2
      backgroundImage: AssetImage(imagePath),
      backgroundColor: AppColors.primaryColor.withOpacity(0.7),
    );
  }

  Widget getAccountItemWidget(AccountItem accountItem) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 15),
      padding: EdgeInsets.symmetric(horizontal: 25),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: SvgPicture.asset(accountItem.iconPath),
          ),
          SizedBox(width: 20),
          Text(
            accountItem.label,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Spacer(),
          Icon(Icons.arrow_forward_ios),
        ],
      ),
    );
  }
}
