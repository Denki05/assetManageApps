// main.dart – Sesuai desain Figma + Reset Search + Overlay Popup untuk Asset
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'models/product.dart';
import 'models/asset_file.dart';
import 'services/api_service.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Roboto', primarySwatch: Colors.indigo),
      home: ProductCatalogApp(),
    ),
  );
}

class ProductCatalogApp extends StatefulWidget {
  const ProductCatalogApp({super.key});

  @override
  State<ProductCatalogApp> createState() => _ProductCatalogAppState();
}

class _ProductCatalogAppState extends State<ProductCatalogApp>
    with SingleTickerProviderStateMixin {
  List<Product> allProducts = [];
  Product? selectedProduct;
  TabController? tabController;
  TextEditingController searchController = TextEditingController();
  List<Product> searchResults = [];

  @override
  void initState() {
    super.initState();
    fetchData();
    tabController = TabController(length: 4, vsync: this);
  }

  Future<void> fetchData() async {
    final data = await ApiService.fetchProducts();
    setState(() => allProducts = data);
  }

  void onSearchChanged(String keyword) {
    if (keyword.isEmpty) {
      setState(() => searchResults = []);
      return;
    }
    final lower = keyword.toLowerCase();
    final results = allProducts.where((p) {
      return p.productCode.toLowerCase().contains(lower) ||
          p.productName.toLowerCase().contains(lower) ||
          (p.searah ?? '').toLowerCase().contains(lower) ||
          p.brandName.toLowerCase().contains(lower);
    }).toList();
    setState(() => searchResults = results);
  }

  List<AssetFile> _filterAssets(String label) {
    return selectedProduct?.assets
            .where((a) => (a.label ?? '').toLowerCase() == label)
            .toList() ??
        [];
  }

  Future<void> _shareAssetFile(String url) async {
    try {
      final response = await Dio().get(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      final tempDir = await getTemporaryDirectory();
      final fileName = url.split('/').last;
      final filePath = '${tempDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(response.data);
      await Share.shareXFiles([
        XFile(filePath),
      ], text: 'Lihat asset produk ini');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal membagikan file.')));
    }
  }

  void _showAssetOverlay(AssetFile asset) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) {
        return Center(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: asset.fileUrl,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    IconButton(
                      icon: Icon(Icons.share, color: Colors.white),
                      onPressed: () => _shareAssetFile(asset.fileUrl),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildAssetGrid(List<AssetFile> assets) {
    if (assets.isEmpty) {
      return Center(child: Text('Tidak ada file'));
    }
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      padding: EdgeInsets.all(12),
      children: assets.map((a) {
        return GestureDetector(
          onTap: () => _showAssetOverlay(a),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(imageUrl: a.fileUrl, fit: BoxFit.cover),
          ),
        );
      }).toList(),
    );
  }

  Widget buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: searchController,
        onChanged: onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search',
          prefixIcon: Icon(Icons.search),
          suffixIcon:
              selectedProduct != null || searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      selectedProduct = null;
                      searchResults = [];
                      searchController.clear();
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + 8),
          buildSearchBar(),
          if (searchResults.isNotEmpty && selectedProduct == null)
            Expanded(
              child: ListView(
                children: searchResults
                    .map(
                      (p) => ListTile(
                        title: Text("${p.productCode} - ${p.productName}"),
                        subtitle: Text(p.searah ?? ''),
                        onTap: () => setState(() {
                          selectedProduct = p;
                          searchController.text =
                              "${p.productCode} - ${p.productName}";
                        }),
                      ),
                    )
                    .toList(),
              ),
            )
          else
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 40,
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: tabController,
                      indicator: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.black,
                      tabs: [
                        Tab(text: 'Catalog'),
                        Tab(text: 'Pord'),
                        Tab(text: 'Ext.Pict'),
                        Tab(text: 'Ext.Vids'),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: selectedProduct == null
                          ? Center(
                              child: Text(
                                'Please search and select the product first',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            )
                          : TabBarView(
                              controller: tabController,
                              children: [
                                buildAssetGrid(_filterAssets('katalog')),
                                buildAssetGrid(
                                  _filterAssets('product_knowladge'),
                                ),
                                buildAssetGrid(_filterAssets('gambar_extra')),
                                buildAssetGrid(_filterAssets('video_extra')),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
