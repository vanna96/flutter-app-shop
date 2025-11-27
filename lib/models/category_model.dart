class CategoryModel {
  final int id;
  final String name;
  final String? khName;
  final String image;
  final List<CategoryModel> children;

  CategoryModel({
    required this.id,
    required this.name,
    required this.image,
    this.khName,
    this.children = const [],
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int,
      name: json['name'] as String,
      khName: json['kh_name'],
      image: json['image'] as String,
      children: json['children'] != null
          ? (json['children'] as List)
          .map((c) => CategoryModel.fromJson(c))
          .toList()
          : [],
    );
  }
}
