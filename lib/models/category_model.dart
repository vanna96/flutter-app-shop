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
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      khName: json['foreign_name']?.toString() ?? json['kh_name']?.toString(),
      image: json['thumbnail_url']?.toString() ??
          json['image_url']?.toString() ??
          json['image']?.toString() ??
          '',
    );
  }
}
