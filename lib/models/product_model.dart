class ProductModel {
  final int id;
  final dynamic name;
  final String? khName;
  final dynamic image;
  final double price;
  final dynamic categoryEn;
  final dynamic categoryKh;
  final dynamic description;

  ProductModel({
    required this.id,
    this.name,
    this.khName,
    this.image,
    required this.price,
    this.categoryEn,
    this.categoryKh,
    this.description
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      name: json['name'] ?? '',                 // nullable
      khName: json['kh_name'] ?? '',            // nullable
      image: json['thumbnail'] ?? '',     // use thumbnail
      price: double.tryParse(json['price'].toString()) ?? 0,
      categoryEn: json['cat_en'] ?? '',
      categoryKh: json['cat_kh'] ?? '',
        description: json['description'] ?? ''
    );
  }
}
