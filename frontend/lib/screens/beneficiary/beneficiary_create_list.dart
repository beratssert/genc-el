import 'package:flutter/material.dart';

class BeneficiaryCreateList extends StatefulWidget {
  const BeneficiaryCreateList({super.key});

  @override
  State<BeneficiaryCreateList> createState() => _BeneficiaryCreateListState();
}

class _BeneficiaryCreateListState extends State<BeneficiaryCreateList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Beneficiary Create List')),
      body: SafeArea(
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                height: 50,
                child: SearchBar(
                  hintText: 'Ürün arayın',
                  onChanged: (value) {},
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: [
                    Card(
                      child: Column(
                        children: [FlutterLogo(), Text('Ürün Adı')],
                      ),
                    ),
                    Card(
                      child: Column(
                        children: [FlutterLogo(), Text('Ürün Adı')],
                      ),
                    ),
                    Card(
                      child: Column(
                        children: [FlutterLogo(), Text('Ürün Adı')],
                      ),
                    ),
                    Card(
                      child: Column(
                        children: [FlutterLogo(), Text('Ürün Adı')],
                      ),
                    ),
                    Card(
                      child: Column(
                        children: [FlutterLogo(), Text('Ürün Adı')],
                      ),
                    ),
                    Card(
                      child: Column(
                        children: [FlutterLogo(), Text('Ürün Adı')],
                      ),
                    ),
                    Card(
                      child: Column(
                        children: [FlutterLogo(), Text('Ürün Adı')],
                      ),
                    ),
                    Card(
                      child: Column(
                        children: [FlutterLogo(), Text('Ürün Adı')],
                      ),
                    ),
                    Card(
                      child: Column(
                        children: [FlutterLogo(), Text('Ürün Adı')],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: Text(
                    "Oluştur",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
