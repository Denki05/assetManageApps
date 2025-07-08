import 'product.dart';

class AssetFile {
  final String filePath;
  final String fileUrl;
  final String fileType;
  final String? label;

  Product? product; // relasi ke produk asal (diisi di runtime)

  AssetFile({
    required this.filePath,
    required this.fileUrl,
    required this.fileType,
    this.label,
    this.product,
  });

  factory AssetFile.fromJson(Map<String, dynamic> json) => AssetFile(
    filePath: json['file_path'],
    fileUrl: json['file_url'],
    fileType: json['file_type'],
    label: json['label'],
  );

  Map<String, dynamic> toJson() => {
    'file_path': filePath,
    'file_url': fileUrl,
    'file_type': fileType,
    'label': label,
  };
}
