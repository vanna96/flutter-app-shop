import 'package:intl/intl.dart';

class CurrencyModel {
  final int? id;
  final String code;
  final String name;
  final String symbol;
  final int decimalPlaces;
  final int sortOrder;
  final String status;
  final double exchangeRate;
  final bool isDefault;

  CurrencyModel({
    this.id,
    required this.code,
    required this.symbol,
    this.name = '',
    this.decimalPlaces = 0,
    this.sortOrder = 0,
    this.status = 'Active',
    this.exchangeRate = 1.0,
    this.isDefault = false,
  });

  bool get hasExchangeRate => isDefault || exchangeRate > 0;

  String format(double amount) {
    final formatter = decimalPlaces > 0
        ? NumberFormat('#,##0.' + '0' * decimalPlaces)
        : NumberFormat('#,##0');
    return '$symbol${formatter.format(amount)}';
  }

  factory CurrencyModel.fromJson(Map<String, dynamic> json) {
    final rawSymbol = json['symbol']?.toString() ??
        json['currency_symbol']?.toString() ??
        '';
    final cleanSymbol = rawSymbol.replaceAll(r'\', '').trim();

    final code = (json['code']?.toString() ??
            json['currency_code']?.toString() ??
            '')
        .trim()
        .toUpperCase();

    final decimals = int.tryParse(
          json['decimal_places']?.toString() ??
              json['decimals']?.toString() ??
              '',
        ) ??
        0;

    final isDefault = json['is_default'] == true ||
        json['is_base'] == true ||
        json['is_default'] == 1 ||
        json['is_default'] == '1';

    final parsedRate = double.tryParse(
      json['exchange_rate']?.toString() ??
          json['rate']?.toString() ??
          json['khr_exchange_rate']?.toString() ??
          '',
    );

    final rate = parsedRate != null && parsedRate > 0
        ? parsedRate
        : (isDefault ? 1.0 : 0.0);

    final sort = int.tryParse(json['sort_order']?.toString() ?? '') ?? 0;

    return CurrencyModel(
      id: int.tryParse(json['id']?.toString() ?? ''),
      code: code,
      name: json['name']?.toString() ?? '',
      symbol: cleanSymbol.isNotEmpty ? cleanSymbol : code,
      decimalPlaces: decimals,
      sortOrder: sort,
      status: json['status']?.toString() ?? 'Active',
      exchangeRate: rate,
      isDefault: isDefault,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'code': code,
        'name': name,
        'symbol': symbol,
        'decimal_places': decimalPlaces,
        'sort_order': sortOrder,
        'status': status,
        'exchange_rate': exchangeRate,
        'is_default': isDefault,
      };
}
