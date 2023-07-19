import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shopping_list_app/data/categories.dart';
import 'package:shopping_list_app/models/grocery_item.dart';
import 'package:shopping_list_app/widgets/new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;
  String? _error; //maybe null si daca nu e null e un string

  @override
  void initState() {
    _loadItems();
    super.initState();
  }

  void _loadItems() async {
    final url = Uri.https(
        'shopping-list-fe25f-default-rtdb.europe-west1.firebasedatabase.app',
        'shopping-list.json');

    try {
      final response = await http.get(url);
      // print(response.body);

      // throw Exception("An error occurred!");

      if (response.statusCode >= 404) {
        setState(() {
          _error = 'Failed to fetch data. Pls try again later.';
        });
      }
      if (response.body == 'null') {
        setState(() {
          _isLoading = false;
        });
        return;
        //e string null pt ca asa il returneaza firebase gen
      }
      //din json in dart objects
      final Map<String, dynamic> listData = json.decode(response.body);
      final List<GroceryItem> loadedItems = [];
      for (final item in listData.entries) {
        final category = categories.entries
            .firstWhere(
                (catItem) => catItem.value.title == item.value['category'])
            .value;

        loadedItems.add(
          GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category,
          ),
        );
      }

      setState(() {
        _groceryItems = loadedItems;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = 'Sth went wrong. Pls try again later.';
      });
    }
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );
    //asteptam userul sa revina ca sa luam datele din firebase
    // _loadItems();
    if (newItem == null) {
      return;
    }
    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });

    final url = Uri.https(
        'shopping-list-fe25f-default-rtdb.europe-west1.firebasedatabase.app',
        'shopping-list/${item.id}.json');

    final response = await http.delete(url);
    //poti adauga si await si async dar e degeaba ca oricum dai swipe
    //si dispare din memoria device ului si de pe ecran
    //si dupa cv timp dispare si din firebase si n-are rost asteptarea

    if (response.statusCode >= 400) {
      //optional show error msg
      setState(() {
        _groceryItems.insert(index, item);
      });
    }
    //daca avem eroare se face undo la delete
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(child: Text('No items added yet'));

    if (_isLoading == true) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (context, index) => Dismissible(
          onDismissed: (direction) {
            _removeItem(_groceryItems[index]);
          },
          key: ValueKey(_groceryItems[index].id),
          child: ListTile(
            title: Text(_groceryItems[index].name),
            leading: Container(
              width: 24,
              height: 24,
              color: _groceryItems[index].category.color,
            ),
            trailing: Text(_groceryItems[index].quantity.toString()),
          ),
        ),
      );
    }

    if (_error != null) {
      content = Center(child: Text(_error!));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your groceries'),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: content,
    );
  }
}
