import 'package:flutter/widgets.dart';

/// Khmer translations for UI copy that is not supplied by the catalog API.
///
/// Catalog names use their backend `foreign_name` fields instead. Keeping this
/// map keyed by the English copy also lets shared widgets translate titles and
/// button labels passed in by their parent screens.
class AppUiTranslations {
  const AppUiTranslations._();

  static const Map<String, String> _km = {
    'Account': 'គណនី',
    'Active': 'សកម្ម',
    'All': 'ទាំងអស់',
    'All Orders': 'ការបញ្ជាទិញទាំងអស់',
    'All Products': 'ផលិតផលទាំងអស់',
    'App Tour & Guide': 'ការណែនាំអំពីកម្មវិធី',
    'Are you sure you want to remove all items from your cart?':
        'តើអ្នកពិតជាចង់លុបទំនិញទាំងអស់ចេញពីរទេះមែនទេ?',
    'Authentication Failed': 'ការផ្ទៀងផ្ទាត់បរាជ័យ',
    'Back To Home': 'ត្រឡប់ទៅទំព័រដើម',
    'Back online': 'បានភ្ជាប់អ៊ីនធឺណិតវិញ',
    'Best Selling': 'លក់ដាច់បំផុត',
    'Cancel': 'បោះបង់',
    'Cart': 'រទេះទំនិញ',
    'Cart Notice': 'សេចក្តីជូនដំណឹងអំពីរទេះ',
    'Category': 'ប្រភេទ',
    'Checking promotions…': 'កំពុងពិនិត្យប្រូម៉ូសិន…',
    'Clear All': 'លុបទាំងអស់',
    'Clear Cart': 'សម្អាតរទេះ',
    'Clear Search': 'សម្អាតការស្វែងរក',
    'Code': 'លេខកូដ',
    'Completed': 'បានបញ្ចប់',
    'Connected to server': 'បានភ្ជាប់ទៅម៉ាស៊ីនមេ',
    'Contact': 'ព័ត៌មានទំនាក់ទំនង',
    'Customer assistance and guide': 'ជំនួយអតិថិជន និងការណែនាំ',
    'DAILY FRESH': 'ស្រស់រាល់ថ្ងៃ',
    'Default': 'លំនាំដើម',
    'Delete': 'លុប',
    'Delete Address': 'លុបអាសយដ្ឋាន',
    'Dismiss': 'បិទ',
    'Delivery': 'ការដឹកជញ្ជូន',
    'Delivery Addresses': 'អាសយដ្ឋានដឹកជញ្ជូន',
    'Developer Settings': 'ការកំណត់អ្នកអភិវឌ្ឍន៍',
    'Display and receipt language': 'ភាសាបង្ហាញ និងវិក្កយបត្រ',
    'Document is empty.': 'ឯកសារនេះមិនមានខ្លឹមសារ។',
    'Edit': 'កែប្រែ',
    'Email': 'អ៊ីមែល',
    'Email / Username': 'អ៊ីមែល / ឈ្មោះអ្នកប្រើ',
    'Explore': 'ស្វែងរក',
    'Explore Products': 'ស្វែងរកផលិតផល',
    'Favourite': 'ចំណូលចិត្ត',
    'Favorites': 'ចំណូលចិត្ត',
    'Filter & Sort': 'តម្រង និងតម្រៀប',
    'Find Products': 'ស្វែងរកផលិតផល',
    'FREE': 'ឥតគិតថ្លៃ',
    'FREE DELIVERY': 'ដឹកជញ្ជូនឥតគិតថ្លៃ',
    'Free reward': 'រង្វាន់ឥតគិតថ្លៃ',
    'Fresh & Smart Shopping': 'ការទិញទំនិញស្រស់ និងឆ្លាតវៃ',
    'Fresh grocery product': 'ផលិតផលគ្រឿងទេសស្រស់',
    'Gender': 'ភេទ',
    'Got it': 'យល់ហើយ',
    'Grand Total': 'សរុបចុងក្រោយ',
    'Help & FAQ': 'ជំនួយ និងសំណួរញឹកញាប់',
    'Help & Guidance': 'ជំនួយ និងការណែនាំ',
    'Home': 'ទំព័រដើម',
    'Home Delivery': 'ដឹកជញ្ជូនដល់ផ្ទះ',
    'How we handle your data': 'របៀបដែលយើងគ្រប់គ្រងទិន្នន័យរបស់អ្នក',
    'Identity': 'អត្តសញ្ញាណ',
    'In Cart': 'ក្នុងរទេះ',
    'Inactive': 'អសកម្ម',
    'Item added to cart': 'បានបន្ថែមទំនិញទៅរទេះ',
    'Items': 'ទំនិញ',
    'Language': 'ភាសា',
    'LIVE RESOLVED ENDPOINT': 'អាសយដ្ឋាន API ដែលកំពុងប្រើ',
    'Load More': 'មើលបន្ថែម',
    'Log Out': 'ចាកចេញ',
    'Login': 'ចូល',
    'Login Successful': 'ចូលប្រើប្រាស់បានជោគជ័យ',
    'Maybe Later': 'ពេលក្រោយ',
    'Matching Categories': 'ប្រភេទដែលត្រូវគ្នា',
    'Matching Products': 'ផលិតផលដែលត្រូវគ្នា',
    'Multi-currency grocery and retail point-of-sale platform.':
        'ប្រព័ន្ធលក់រាយ និងគ្រឿងទេសដែលគាំទ្ររូបិយប័ណ្ណច្រើន។',
    'My Addresses': 'អាសយដ្ឋានរបស់ខ្ញុំ',
    'My Cart': 'រទេះទំនិញរបស់ខ្ញុំ',
    'My Favorites': 'ចំណូលចិត្តរបស់ខ្ញុំ',
    'My Profile': 'ប្រវត្តិរូបរបស់ខ្ញុំ',
    'Network Settings': 'ការកំណត់បណ្តាញ',
    'New Arrival': 'ទំនិញថ្មី',
    'NEXT': 'បន្ទាប់',
    'No categories found': 'រកមិនឃើញប្រភេទទំនិញ',
    'No Favorites Yet': 'មិនទាន់មានចំណូលចិត្ត',
    'No Internet Connection': 'គ្មានការតភ្ជាប់អ៊ីនធឺណិត',
    'No items found': 'រកមិនឃើញទំនិញ',
    'No matching orders': 'រកមិនឃើញការបញ្ជាទិញដែលត្រូវគ្នា',
    'No Notifications': 'មិនមានការជូនដំណឹង',
    'No option configurations available for this item.':
        'មិនមានជម្រើសកំណត់សម្រាប់ទំនិញនេះទេ។',
    'No Orders Yet': 'មិនទាន់មានការបញ្ជាទិញ',
    'No products found': 'រកមិនឃើញផលិតផល',
    'Notifications': 'ការជូនដំណឹង',
    'Open video': 'បើកវីដេអូ',
    'Options': 'ជម្រើស',
    'Order History': 'ប្រវត្តិការបញ្ជាទិញ',
    'Order Items': 'ទំនិញក្នុងការបញ្ជាទិញ',
    'Order Receipt': 'វិក្កយបត្របញ្ជាទិញ',
    'Order updates and promos': 'ព័ត៌មានការបញ្ជាទិញ និងប្រូម៉ូសិន',
    'Orders': 'ការបញ្ជាទិញ',
    'Out of Stock': 'អស់ពីស្តុក',
    'Password': 'ពាក្យសម្ងាត់',
    'Pending': 'កំពុងរង់ចាំ',
    'Please login to continue': 'សូមចូលប្រើប្រាស់ដើម្បីបន្ត',
    'Please sign in to continue to checkout.':
        'សូមចូលប្រើប្រាស់ដើម្បីបន្តការទូទាត់។',
    'Privacy Policy': 'គោលការណ៍ឯកជនភាព',
    'Product Description': 'ការពិពណ៌នាផលិតផល',
    'Products you saved for later': 'ផលិតផលដែលអ្នកបានរក្សាទុក',
    'Promo Code': 'លេខកូដប្រូម៉ូសិន',
    'Promo price': 'តម្លៃប្រូម៉ូសិន',
    'Promotion Discount': 'ការបញ្ចុះតម្លៃប្រូម៉ូសិន',
    'Quantity:': 'បរិមាណ៖',
    'Read our terms of service': 'អានលក្ខខណ្ឌប្រើប្រាស់របស់យើង',
    'Remember me': 'ចងចាំខ្ញុំ',
    'Reorder Items': 'បញ្ជាទិញម្តងទៀត',
    'Reset': 'កំណត់ឡើងវិញ',
    'Reset Filters': 'កំណត់តម្រងឡើងវិញ',
    'Retry': 'ព្យាយាមម្តងទៀត',
    'Save Changes': 'រក្សាទុកការផ្លាស់ប្តូរ',
    'Saved delivery destinations': 'ទីតាំងដឹកជញ្ជូនដែលបានរក្សាទុក',
    'Saving Order...': 'កំពុងរក្សាទុកការបញ្ជាទិញ...',
    'Search': 'ស្វែងរក',
    'Searching products...': 'កំពុងស្វែងរកផលិតផល...',
    'Search order #, item, or payment...':
        'ស្វែងរកលេខបញ្ជាទិញ ទំនិញ ឬការទូទាត់...',
    'See All': 'មើលទាំងអស់',
    'Select Language': 'ជ្រើសរើសភាសា',
    'Select Location': 'ជ្រើសរើសទីតាំង',
    'Select Method': 'ជ្រើសរើសវិធីសាស្ត្រ',
    'Select Unit of Measure (UOM)': 'ជ្រើសរើសឯកតារង្វាស់',
    'Select Unit of Measure (UOM):': 'ជ្រើសរើសឯកតារង្វាស់៖',
    'Server & Tenant Settings': 'ការកំណត់ម៉ាស៊ីនមេ និងអ្នកជួល',
    'Set as default address': 'កំណត់ជាអាសយដ្ឋានលំនាំដើម',
    'Set Default': 'កំណត់ជាលំនាំដើម',
    'Shop': 'ហាង',
    'Shopping & Orders': 'ការទិញ និងការបញ្ជាទិញ',
    'SKIP': 'រំលង',
    'Sort': 'តម្រៀប',
    'Sort By': 'តម្រៀបតាម',
    'Special Offer': 'ការផ្តល់ជូនពិសេស',
    'Start Shopping': 'ចាប់ផ្តើមទិញទំនិញ',
    'Subtotal': 'សរុបរង',
    'Support & System': 'ជំនួយ និងប្រព័ន្ធ',
    'Tap the heart icon on any product to save items you love for easy shopping later.':
        'ចុចរូបបេះដូងលើផលិតផល ដើម្បីរក្សាទុកទំនិញដែលអ្នកចូលចិត្ត។',
    'Terms & Conditions': 'លក្ខខណ្ឌប្រើប្រាស់',
    'This item is flagged for customer garment virtual preview':
        'ទំនិញនេះគាំទ្រការសាកល្បងសម្លៀកបំពាក់និម្មិត',
    'Total Paid': 'ប្រាក់បានបង់សរុប',
    'Copy Invoice #': 'ចម្លងលេខវិក្កយបត្រ',
    'Track past purchases & receipts': 'តាមដានការទិញ និងវិក្កយបត្រចាស់ៗ',
    'Try Again': 'ព្យាយាមម្តងទៀត',
    'Try adjusting your search or category filter.':
        'សូមកែសម្រួលពាក្យស្វែងរក ឬតម្រងប្រភេទ។',
    'Try-On Ready': 'អាចសាកល្បងនិម្មិត',
    'Unable to Place Order': 'មិនអាចបញ្ជាទិញបាន',
    'Update Now': 'អាប់ដេតឥឡូវនេះ',
    'Update required to continue': 'ត្រូវការអាប់ដេតដើម្បីបន្ត',
    'Upload Profile Photo': 'បង្ហោះរូបថតប្រវត្តិរូប',
    'Use your POS operator or demo credentials to sign in.':
        'ប្រើគណនីប្រតិបត្តិករ POS ឬគណនីសាកល្បងដើម្បីចូល។',
    'View Cart': 'មើលរទេះ',
    'View features and walkthrough guide': 'មើលមុខងារ និងការណែនាំប្រើប្រាស់',
    'Virtual Try-On Supported': 'គាំទ្រការសាកល្បងនិម្មិត',
    'Welcome Back': 'សូមស្វាគមន៍មកវិញ',
    'Welcome back to your account.': 'សូមស្វាគមន៍មកកាន់គណនីរបស់អ្នកវិញ។',
    "You're Offline": 'អ្នកកំពុងក្រៅបណ្តាញ',
    'Your Cart is Empty': 'រទេះទំនិញរបស់អ្នកទទេ',
    'You Order Has Been Accepted': 'ការបញ្ជាទិញរបស់អ្នកត្រូវបានទទួល',
    "Your item has been placed and is on it's way to being processed":
        'ការបញ្ជាទិញរបស់អ្នកត្រូវបានដាក់បញ្ចូល និងកំពុងដំណើរការ',
    'About': 'អំពីកម្មវិធី',
    'About V-POS': 'អំពី V-POS',
    'Add': 'បន្ថែម',
    'Add Address': 'បន្ថែមអាសយដ្ឋាន',
    'Add New Address': 'បន្ថែមអាសយដ្ឋានថ្មី',
    'Add To Basket': 'បន្ថែមទៅកន្រក',
    'Add to Cart': 'បន្ថែមទៅរទេះទំនិញ',
    'Adding...': 'កំពុងបន្ថែម...',
    'Address': 'អាសយដ្ឋាន',
    'Address Line': 'អាសយដ្ឋានលម្អិត',
    'All Branches': 'សាខាទាំងអស់',
    'All Categories': 'ប្រភេទទាំងអស់',
    'All your past orders and receipts will be saved and organized here in real time.':
        'ការបញ្ជាទិញ និងវិក្កយបត្រចាស់របស់អ្នកនឹងត្រូវបានរក្សាទុក និងរៀបចំនៅទីនេះ។',
    'Back Online!': 'បានភ្ជាប់អ៊ីនធឺណិតវិញ!',
    'Bank': 'ធនាគារ',
    'Base unit': 'ឯកតាគោល',
    'Card': 'កាត',
    'Cash': 'សាច់ប្រាក់',
    'Checkout': 'ទូទាត់',
    'City': 'ទីក្រុង',
    'Conditions': 'លក្ខខណ្ឌ',
    'Configure Connection': 'កំណត់ការភ្ជាប់',
    'Create a delivery address to preview how the account flow looks.':
        'បង្កើតអាសយដ្ឋានដឹកជញ្ជូនដើម្បីប្រើនៅពេលទូទាត់។',
    'Delivery Address Book': 'បញ្ជីអាសយដ្ឋានដឹកជញ្ជូន',
    'Delivery Fee': 'ថ្លៃដឹកជញ្ជូន',
    'Edit Address': 'កែប្រែអាសយដ្ឋាន',
    'Failed': 'បរាជ័យ',
    'Failed to load document.': 'មិនអាចផ្ទុកឯកសារបានទេ។',
    'Featured': 'ពិសេស',
    'Female': 'ស្រី',
    'First Name': 'នាមខ្លួន',
    'Free': 'ឥតគិតថ្លៃ',
    'Get Started': 'ចាប់ផ្តើម',
    'GET STARTED': 'ចាប់ផ្តើម',
    'Items Added to Cart': 'ទំនិញដែលបានបន្ថែមទៅរទេះ',
    'Label': 'ស្លាក',
    'Last Name': 'នាមត្រកូល',
    'Login Required': 'ត្រូវចូលប្រើប្រាស់',
    'Male': 'ប្រុស',
    'Name': 'ឈ្មោះ',
    'New': 'ថ្មី',
    'No addresses yet': 'មិនទាន់មានអាសយដ្ឋាន',
    'No content available.': 'មិនមានខ្លឹមសារទេ។',
    'No automatic promotion applies to this cart.':
        'មិនមានប្រូម៉ូសិនស្វ័យប្រវត្តិសម្រាប់រទេះនេះទេ។',
    'Out of stock': 'អស់ពីស្តុក',
    'Payment': 'ការទូទាត់',
    'Payment Method': 'វិធីសាស្ត្រទូទាត់',
    'Place Order': 'បញ្ជាទិញ',
    'Please check your Wi-Fi or mobile network connection and try again.':
        'សូមពិនិត្យការភ្ជាប់ Wi-Fi ឬបណ្តាញទូរស័ព្ទ ហើយព្យាយាមម្តងទៀត។',
    'Please Try Again': 'សូមព្យាយាមម្តងទៀត',
    'Proceed to Checkout': 'បន្តទៅការទូទាត់',
    'Premium': 'ព្រីមៀម',
    'Product Details': 'ព័ត៌មានលម្អិតផលិតផល',
    'Promotion': 'ប្រូម៉ូសិន',
    'Save Address': 'រក្សាទុកអាសយដ្ឋាន',
    'Save Profile': 'រក្សាទុកប្រវត្តិរូប',
    'Save Settings': 'រក្សាទុកការកំណត់',
    'Search Products': 'ស្វែងរកផលិតផល',
    'Discover fresh groceries, exclusive discounts, and promotional items from our shop.':
        'ស្វែងរកទំនិញស្រស់ថ្មី ការបញ្ចុះតម្លៃពិសេស និងទំនិញប្រូម៉ូសិនពីហាងរបស់យើង។',
    'SHOPPING & ORDERS': 'ការទិញ និងការបញ្ជាទិញ',
    'PREFERENCES': 'ចំណូលចិត្ត',
    'SUPPORT & SYSTEM': 'ជំនួយ និងប្រព័ន្ធ',
    'Total Cost': 'តម្លៃសរុប',
    'Try-On': 'សាកល្បង',
    'UOM': 'ឯកតារង្វាស់',
    'Update Cart': 'កែប្រែរទេះទំនិញ',
    'Username': 'ឈ្មោះអ្នកប្រើ',
    'Welcome': 'សូមស្វាគមន៍',
    'Oops! Order Failed': 'ការបញ្ជាទិញបរាជ័យ',
    'Something went temply wrong': 'មានបញ្ហាបណ្តោះអាសន្ន',
    "Today's exchange rate is not configured for KHR.":
        'អត្រាប្តូរប្រាក់ថ្ងៃនេះមិនទាន់បានកំណត់សម្រាប់ KHR ទេ។',
    'Exchange rate not set. Please configure in settings.':
        'អត្រាប្តូរប្រាក់មិនទាន់បានកំណត់ទេ។ សូមកំណត់ក្នុងផ្ទាំងគ្រប់គ្រង។',
    'Exchange Rate': 'អត្រាប្តូរប្រាក់',
    'Rate not set': 'មិនទាន់កំណត់អត្រា',
    'By placing an order you agree to our Terms And Conditions':
        'ការដាក់បញ្ជាទិញមានន័យថាអ្នកយល់ព្រមនឹងលក្ខខណ្ឌរបស់យើង',
  };

  static String text(BuildContext context, String value) {
    if (Localizations.localeOf(context).languageCode != 'km' ||
        value.trim().isEmpty) {
      return value;
    }

    final exact = _km[value];
    if (exact != null) return exact;

    final trimmed = value.trim();
    final trimmedMatch = _km[trimmed];
    if (trimmedMatch != null) {
      return value.replaceFirst(trimmed, trimmedMatch);
    }

    final rateMatch = RegExp(r"^Today's exchange rate is not configured for (.*)\.$").firstMatch(value);
    if (rateMatch != null) {
      final code = rateMatch.group(1);
      return 'អត្រាប្តូរប្រាក់ថ្ងៃនេះមិនទាន់បានកំណត់សម្រាប់ $code ទេ។';
    }
    final notSetMatch = RegExp(r"^Rate for (.*) not set$").firstMatch(value);
    if (notSetMatch != null) {
      final code = notSetMatch.group(1);
      return 'មិនទាន់កំណត់អត្រាសម្រាប់ $code';
    }

    if (value.startsWith('Search in ') && value.endsWith('...')) {
      return 'ស្វែងរកក្នុង ${value.substring(10)}';
    }
    if (value.startsWith('Select ') && value.endsWith(':')) {
      return 'ជ្រើសរើស ${value.substring(7, value.length - 1)}៖';
    }
    if (value.startsWith('Base Price:')) {
      return value.replaceFirst('Base Price:', 'តម្លៃគោល៖');
    }
    if (value.startsWith('Pay ')) {
      return 'បង់ប្រាក់ ${text(context, value.substring(4))}';
    }
    if (value.startsWith('Qty: ')) {
      return value.replaceFirst('Qty: ', 'ចំនួន៖ ');
    }
    if (value.startsWith('Invoice: ')) {
      return value.replaceFirst('Invoice: ', 'វិក្កយបត្រ៖ ');
    }
    if (value.endsWith(' saved')) {
      return '${value.substring(0, value.length - 6)} បានរក្សាទុក';
    }
    if (value.endsWith(' Items included')) {
      return '${value.substring(0, value.length - 15)} ទំនិញ';
    }
    if (value.endsWith(' each')) {
      return '${value.substring(0, value.length - 5)} ក្នុងមួយឯកតា';
    }
    if (value.endsWith('/unit')) {
      return value.replaceFirst('/unit', '/ឯកតា');
    }
    if (value.startsWith('UOM:')) {
      return value.replaceFirst('UOM:', 'ឯកតារង្វាស់៖');
    }
    if (value.endsWith(' order') || value.endsWith(' orders')) {
      return '${value.split(' ').first} ការបញ្ជាទិញ';
    }
    if (value.endsWith(' item') || value.endsWith(' items')) {
      return '${value.split(' ').first} ទំនិញ';
    }
    if (value.contains(' saved address')) {
      return '${value.split(' ').first} អាសយដ្ឋានដែលបានរក្សាទុក';
    }
    if (value.startsWith('No products found for ') ||
        value.startsWith('No results found for ')) {
      final query = value.substring(value.indexOf('for ') + 4);
      return 'រកមិនឃើញលទ្ធផលសម្រាប់ $query';
    }

    return value;
  }
}
