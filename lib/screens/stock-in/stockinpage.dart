import 'package:flutter/material.dart';
import 'package:msic/services/api_service.dart';

class Stockinpage extends StatefulWidget {
  const Stockinpage({super.key});
  @override
  State<Stockinpage> createState() => _StockinpageState();
}

class _StockinpageState extends State<Stockinpage> {
  final _api = ApiService(); //call api serive
  List<Map<String, dynamic>> _items = []; // data from api with put in a list
  bool _loading = false; // loading indicator

  @override
  void initState() {
    super.initState();
    _loadData(); //this will load data from api when the page is loaded
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final data = await _api.getStockInList(context);
    setState(() {
      _items = data; //save data to item list
      _loading = false; // hide loading
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Stock-In Records")),
      body: _loading
          ? Center(child: Text("No records found"))
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return Card(
                  child: ListTile(
                    title: Text(item['DO Number'] ?? '-'),
                    subtitle: Text(item['Supplier Name'] ?? '-'),
                  ),
                );
              },
            ),
    );
  }
}
