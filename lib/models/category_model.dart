class CategoryModel {
  final int id;
  final String name;
  final String? khName; // optional
  final String image;

  CategoryModel({
    required this.id,
    required this.name,
    required this.image,
    this.khName,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int,
      name: json['name'] as String,
      khName: json['kh_name'] != null ? json['kh_name'] as String : null,
      image: json['image'] as String,
    );
  }
}