class AccountItem {
  final String label;
  final String iconPath;

  AccountItem(this.label, this.iconPath);
}

List<AccountItem> accountItems = [
  AccountItem("My Profile", "assets/icons/account_icons/details_icon.svg"),
  AccountItem("My Favorite", "assets/icons/account_icons/fav_icon.svg"),
  AccountItem("Address", "assets/icons/account_icons/delivery_icon.svg"),
  AccountItem("Notifications", "assets/icons/account_icons/notification_icon.svg"),
  AccountItem("Help", "assets/icons/account_icons/help_icon.svg"),
  AccountItem("About", "assets/icons/account_icons/about_icon.svg"),
];
