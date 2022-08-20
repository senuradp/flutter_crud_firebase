import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //initilaize firebase
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter CRUD demo',
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //refer to the table/collection we created in firestore
  final CollectionReference _products =
      FirebaseFirestore.instance.collection('products');

  //textview controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  //update method
  Future<void> _update([DocumentSnapshot? documentSnapshot]) async {
    if (documentSnapshot != null) {
      //get the current value from the document object and store them in _nameController and _priceController
      _nameController.text = documentSnapshot['name'];
      _priceController.text = documentSnapshot['price'].toString();
    }
    //to show the data as we work on it
    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            //prevent the keyboard from covering text fields
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //1. above controllers to get the current value in the database
              //2. text fields to get the changed value
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              TextField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: "Price"),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(
                height: 20,
              ),
              ElevatedButton(
                onPressed: () async {
                  //3. save the changed values to name and price
                  final String name = _nameController.text;
                  final double? price = double.tryParse(_priceController.text);
                  if (price != null) {
                    await _products
                        // as we are trying to update we need to pass the id which comes from the document
                        .doc(documentSnapshot!.id)
                        //4. and pass the changed values to the update methods
                        .update({"name": name, "price": price});
                    //close modal after update clicked
                    Navigator.of(context).pop();
                    // _nameController.text = '';
                    // _priceController.text = '';
                  }
                },
                child: const Text("Update"),
              )
            ],
          ),
        );
      },
    );
  }

  //add method
  Future<void> _create([DocumentSnapshot? documentSnapshot]) async {
    _nameController.text = '';
    _priceController.text = '';
    await showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (BuildContext ctx) {
          return Padding(
            padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  child: const Text("Add"),
                  onPressed: () async {
                    final String name = _nameController.text;
                    final double? price =
                        double.tryParse(_priceController.text);
                    if (price != null) {
                      await _products.add({"name": name, "price": price});
                      // _nameController.text = '';
                      // _priceController.text = '';
                      Navigator.of(context).pop();
                    }
                  },
                )
              ],
            ),
          );
        });
  }

  //delete method
  Future<void> _delete(String productId) async {
    await _products.doc(productId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Record successfully deleted !"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _create();
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      //stream builder helps keeps a persistent connection with firestore database
      //because of stream builder we can get updated data in real time.
      body: StreamBuilder(
        //build connection with the collection
        //snapshots is coming from _products above
        stream: _products.snapshots(),
        //stream snapshots will have all the data available in the database
        builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
          //chekck for data (if we have data)
          if (streamSnapshot.hasData) {
            //if we have data show the data in a list view builder
            //list view builder will look thriugh all the data we have in our database
            return ListView.builder(
              //inside this we access the data from the table
              //docs refe to the rows in firestore database
              //since stream snapshot contains all the data we can access using streamSnapshot.data,
              //access the rows and its length(number of rows)
              itemCount: streamSnapshot.data!.docs.length,
              itemBuilder: (context, index) {
                //access the data from the row and save it in a Document object
                final DocumentSnapshot documentSnapshot =
                    streamSnapshot.data!.docs[index];
                //since Datasnapshot object refers to rows, we can access the columns/fields in the rows
                //using the property name and proce in the database
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    title: Text(documentSnapshot['name']),
                    subtitle: Text(documentSnapshot['price'].toString()),
                    //a widget to display after the title
                    trailing: SizedBox(
                      width: 100,
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              // we pass the snapshot since it has the index value to pinpoint the required row
                              _update(documentSnapshot);
                            },
                            icon: const Icon(Icons.edit),
                          ),
                          IconButton(
                            onPressed: () {
                              // we pass the snapshot since it has the index value to pinpoint the required row
                              _delete(documentSnapshot.id);
                            },
                            icon: const Icon(Icons.delete),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
          //else show the rotating progress bar
          else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}
