import 'package:flutter/material.dart';

class BeneficiaryMainScreen extends StatefulWidget {
  const BeneficiaryMainScreen({super.key});

  @override
  State<BeneficiaryMainScreen> createState() => _BeneficiaryMainScreenState();
}

class _BeneficiaryMainScreenState extends State<BeneficiaryMainScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Beneficiary Main Screen')),
      body: Column(
        children: [
          Text("Ihtiyac listesi \n oluştur", style: TextStyle(fontSize: 48)),
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
          SizedBox(height: 20),
          Text("Gecmiş İhtiyaçlarım"),
        ],
      ),
    );
  }
}
