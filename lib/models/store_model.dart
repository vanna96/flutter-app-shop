import 'package:html/parser.dart' as html_parser;

class StoreModel {
  final int id;
  final String image;
  final dynamic name;
  final dynamic khName;
  final dynamic description;

  StoreModel({required this.id, required this.image, this.name, this.description, this.khName});

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
        id: json['id'],
        image: json['image'],
        name: json['name'],
        khName: json['kh_name'],
        description: stripHtml(json['description']),
    );
  }
}

String stripHtml(String? htmlString) {
  if (htmlString == null) return '';
  final document = html_parser.parse(htmlString);
  return document.body?.text.trim() ?? '';
}