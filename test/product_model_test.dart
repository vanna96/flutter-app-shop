import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_app/models/currency_model.dart';
import 'package:grocery_app/models/product_model.dart';

void main() {
  test('retains backend foreign names for catalog and UOM data', () {
    final product = ProductModel.fromJson({
      'id': 10,
      'sku': 'BANANA-01',
      'name': 'Organic Banana',
      'foreign_name': 'ចេកសរីរាង្គ',
      'price': 3.5,
      'category': {'name': 'Fresh Fruits', 'foreign_name': 'ផ្លែឈើស្រស់'},
      'uom_group': {
        'name': 'Each group',
        'foreign_name': 'ក្រុមឯកតា',
        'units': [
          {
            'id': 1,
            'name': 'Each',
            'foreign_name': 'មួយ',
            'code': 'EA',
            'symbol': 'ea',
            'conversion_factor_to_base': 1,
            'is_base_unit': true,
            'base_price': 3.5,
            'price': 3.5,
            'is_active': true,
          },
        ],
      },
    });

    expect(product.khName, 'ចេកសរីរាង្គ');
    expect(product.categoryKh, 'ផ្លែឈើស្រស់');
    expect(product.uomGroupForeignName, 'ក្រុមឯកតា');
    expect(product.defaultUOMForeignName, 'មួយ');
    expect(product.uomList.single.foreignName, 'មួយ');
    expect(product.toJson()['uom_group']['foreign_name'], 'ក្រុមឯកតា');
    expect(product.toJson()['uom_group']['units'][0]['foreign_name'], 'មួយ');
  });

  test('ProductModel parses currency directly from backend API fields', () {
    final productWithDirectFields = ProductModel.fromJson({
      'id': 2,
      'name': 'API Currency Product',
      'price': 349.99,
      'currency_symbol': r'$',
      'currency_code': 'USD',
    });
    expect(productWithDirectFields.currencySymbol, r'$');
    expect(productWithDirectFields.currencyCode, 'USD');

    final productKhr = ProductModel.fromJson({
      'id': 3,
      'name': 'KHR Product',
      'price': 1400000.0,
      'currency': {'symbol': '៛', 'code': 'KHR'},
    });
    expect(productKhr.currencySymbol, '៛');
    expect(productKhr.currencyCode, 'KHR');

    // Cleans backslash if backend accidentally sends escaping slashes
    final productWithBackslash = ProductModel.fromJson({
      'id': 4,
      'name': 'Backslash Item',
      'price': 349.99,
      'currency': {'symbol': r'\$', 'code': 'USD'},
    });
    expect(productWithBackslash.currencySymbol, r'$');
  });

  test('CurrencyModel parses backend currency table entries', () {
    final khr = CurrencyModel.fromJson({
      'code': 'KHR',
      'name': 'KHR',
      'symbol': '៛',
      'decimal_places': 0,
      'exchange_rate': 4100.0,
    });
    expect(khr.code, 'KHR');
    expect(khr.symbol, '៛');
    expect(khr.decimalPlaces, 0);
    expect(khr.exchangeRate, 4100.0);

    final usd = CurrencyModel.fromJson({
      'code': 'USD',
      'name': 'USD',
      'symbol': r'$',
      'decimal_places': 2,
      'exchange_rate': 1.0,
      'is_default': true,
    });
    expect(usd.code, 'USD');
    expect(usd.symbol, r'$');
    expect(usd.decimalPlaces, 2);
    expect(usd.isDefault, true);
  });

  test('Milk Tea extra toppings requires one and allows at most two', () {
    final milkTea = ProductModel.fromJson({
      'id': 20,
      'name': 'Milk Tea',
      'price': 3.0,
      'option_groups': [
        {
          'id': 200,
          'name': 'Extra Toppings',
          'type': 'modifier',
          'selection_type': 'multiple',
          'is_required': true,
          'min_selections': 1,
          'max_selections': 2,
          'values': [
            {'id': 1, 'name': 'Pearls', 'price_adjustment': 0.5},
            {'id': 2, 'name': 'Pudding', 'price_adjustment': 0.75},
            {'id': 3, 'name': 'Grass Jelly', 'price_adjustment': 0.5},
          ],
        },
      ],
    });

    final toppings = milkTea.optionGroups.single;
    expect(toppings.allowsMultiple, isTrue);
    expect(toppings.effectiveMinimumSelections, 1);
    expect(toppings.effectiveMaximumSelections, 2);
    expect(toppings.isSelectionCountValid(0), isFalse);
    expect(toppings.isSelectionCountValid(1), isTrue);
    expect(toppings.isSelectionCountValid(2), isTrue);
    expect(toppings.isSelectionCountValid(3), isFalse);
  });

  test('optional single-select groups allow an empty selection', () {
    final group = ProductOptionGroup.fromJson({
      'id': 300,
      'name': 'Sweetener',
      'selection_type': 'single',
      'is_required': '0',
      'min_selections': 1,
      'max_selections': 1,
    });

    expect(group.isRequired, isFalse);
    expect(group.allowsMultiple, isFalse);
    expect(group.effectiveMinimumSelections, 0);
    expect(group.effectiveMaximumSelections, 1);
    expect(group.isSelectionCountValid(0), isTrue);
    expect(group.isSelectionCountValid(1), isTrue);
    expect(group.isSelectionCountValid(2), isFalse);
  });
}
