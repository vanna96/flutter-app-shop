import 'package:html/parser.dart' as html_parser;

class StoreModel {
  final int id;
  final String image;
  final String name;
  final String? khName;
  final String description;

  StoreModel({
    required this.id,
    required this.image,
    required this.name,
    required this.description,
    this.khName,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      image: json['image_url']?.toString() ??
          json['thumbnail_url']?.toString() ??
          json['image']?.toString() ??
          'assets/images/shop.png',
      name: json['name']?.toString() ?? '',
      khName: json['foreign_name']?.toString() ?? json['kh_name']?.toString(),
      description: stripHtml(
        json['location']?.toString() ?? json['description']?.toString(),
      ),
    );
  }
}

String stripHtml(String? htmlString) {
  if (htmlString == null) return '';
  final document = html_parser.parse(htmlString);
  return document.body?.text.trim() ?? '';
}
