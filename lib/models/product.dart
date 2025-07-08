import 'asset_file.dart';

class Product {
  final String id;
  final String productCode;
  final String productName;
  final String brandName;
  final String? searah; // ← Tambahan field ini
  final String? note;
  final List<AssetFile> assets;

  Product({
    required this.id,
    required this.productCode,
    required this.productName,
    required this.brandName,
    this.searah,
    this.note,
    required this.assets,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'].toString(),
    productCode: json['product_code'] ?? '',
    productName: json['product_name'] ?? '',
    brandName: json['brand_name'] ?? '',
    searah: json['searah'],
    note: json['note'],
    assets: (json['assets'] as List<dynamic>)
        .map((e) => AssetFile.fromJson(e))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_code': productCode,
    'product_name': productName,
    'brand_name': brandName,
    'searah': searah,
    'note': note,
    'assets': assets.map((a) => a.toJson()).toList(),
  };
}
