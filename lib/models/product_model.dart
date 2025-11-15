class ProductModel {
  final int id;
  final String name;
  final String image;
  final double price;

  ProductModel({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      name: json['name'],
      image: json['image'],
      price: double.parse(json['price'].toString()),
    );
  }
}
