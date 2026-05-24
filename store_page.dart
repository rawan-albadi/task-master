import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_auth_service.dart';

class Pet {
  final String name;
  final String assetPath;
  final bool isAnimated;

  Pet({required this.name, required this.assetPath, this.isAnimated = false});
}

class StorePage extends StatefulWidget {
  final int points;
  final List<String> purchased;
  final Function(Color, int, String) onColorPurchased;
  final Function(String, int) onPetPurchased;
  final Function(String) onPetUse;
  final String selectedPet;
   final Function(int) onCoinsUpdated; 

  const StorePage({super.key, 
    required this.points,
    required this.purchased,
    required this.onColorPurchased,
    required this.onPetPurchased,
    required this.onPetUse,
    required this.selectedPet,
    required this.onCoinsUpdated,
  });

  @override
  _StorePageState createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  late int coins;
  late List<String> purchasedItems;

  static const int BACKGROUND_PRICE = 15;
  static const int GACHA_PRICE = 30;

  final Map<String, Color> backgroundColors = {
    'Mint': Color(0xFFB2F2BB),
    'Sky Blue': Color(0xFF74C0FC),
    'Lavender': Color(0xFFE5DBFF),
    'Peach': Color(0xFFFFD6A5),
    'Light Yellow': Color(0xFFFFF3BF),
  };

  String selectedColorName = '';

  List<Pet> gachaPets = [
    Pet(name: 'Crab', assetPath: 'assets/lottie/1.json', isAnimated: true),
    Pet(name: 'Hamster', assetPath: 'assets/lottie/2.json', isAnimated: true),
    Pet(name: 'Turtle', assetPath: 'assets/lottie/3.json', isAnimated: true),
    Pet(name: 'Cat', assetPath: 'assets/lottie/4.json', isAnimated: true),
    Pet(name: 'Cat', assetPath: 'assets/lottie/5.json', isAnimated: true),
  ];

  List<Pet> ownedPets = [];

  @override
  void initState() {
    super.initState();
    coins = widget.points;
    purchasedItems = List<String>.from(widget.purchased);
    _loadOwnedPets();
  }

  Future<void> _loadOwnedPets() async {
    final user = FirebaseAuthService.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        final petPaths = List<String>.from(data?['ownedPets'] ?? []);
        setState(() {
          ownedPets = petPaths.map((path) => Pet(name: 'Pet', assetPath: path, isAnimated: true)).toList();
        });
      }
    }
  }

  Future<void> _updateUserData() async {
    final user = FirebaseAuthService.currentUser;
    if (user != null) {
      final ownedPetPaths = ownedPets.map((pet) => pet.assetPath).toList();
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'coins': coins,
        'purchased': purchasedItems,
        'ownedPets': ownedPetPaths,
      });
    }
  }

  void _buyBackgroundColor(String colorName, Color color) {
    if (purchasedItems.contains(colorName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You already own this color!')),
      );
      return;
    }

    if (coins >= BACKGROUND_PRICE) {
      setState(() {
        coins -= BACKGROUND_PRICE;
        purchasedItems.add(colorName);
        selectedColorName = colorName;
      });

      widget.onColorPurchased(color, BACKGROUND_PRICE, colorName);
      _updateUserData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Color purchased successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Not enough coins!')),
      );
    }
  }

  void _pullGacha() {
  if (coins >= GACHA_PRICE) {
    final random = Random();
    final randomPet = gachaPets[random.nextInt(gachaPets.length)];
    
    setState(() {
      coins -= GACHA_PRICE;
      ownedPets.add(randomPet);
    });

    _updateUserData(); 

    widget.onCoinsUpdated(coins); 

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("You got: ${randomPet.name}! 🎉"),
        content: SizedBox(
          width: 150,
          height: 150,
          child: randomPet.isAnimated
              ? Lottie.asset(randomPet.assetPath)
              : Image.asset(randomPet.assetPath),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Not enough coins for gacha!')),
    );
  }
}

  @override
  void dispose() {
    Navigator.pop(context, coins); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Store & Gift', style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 36,
                  color: Color(0xFF512DA8), // Deep Purple 700
                  letterSpacing: 1.2,
                ),),
                centerTitle: true,
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          Chip(
            label: Text('Coins: $coins'),
            avatar: Icon(Icons.monetization_on, color: Colors.amber),
          ),
          SizedBox(height: 20),
          Text('Choose Background Color: ($BACKGROUND_PRICE coins)',
              style: TextStyle(fontSize: 18)),
          SizedBox(height: 10),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: backgroundColors.length,
              itemBuilder: (context, index) {
                final entry = backgroundColors.entries.elementAt(index);
                return _buildColorItem(entry.key, entry.value);
              },
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _pullGacha,
            icon: Icon(Icons.card_giftcard),
            label: Text('Gacha Pull ($GACHA_PRICE coins)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
          ),
          SizedBox(height: 20),
          Text('Your Pets:', style: TextStyle(fontSize: 18)),
          Expanded(
            child: ownedPets.isEmpty
                ? Center(child: Text('No pets yet'))
                : GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 1,
                    ),
                    itemCount: ownedPets.length,
                    itemBuilder: (context, index) => _buildPetItem(ownedPets[index]),
                  ),
          ),
        ],
      ),
    );
  }

 Widget _buildColorItem(String name, Color color) {
  final isOwned = purchasedItems.contains(name);
  final isSelected = selectedColorName == name;

  return Container(
    width: 120,
    margin: EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: isSelected ? Colors.blue : Colors.grey,
        width: 2,
      ),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          name,
          style: TextStyle(
              fontWeight: FontWeight.bold, backgroundColor: Colors.white70),
        ),
        SizedBox(height: 5),
        if (isOwned)
          Icon(Icons.check_circle, color: Colors.green),
        SizedBox(height: 5),
        if (!isOwned)
          ElevatedButton(
            onPressed: () => _buyBackgroundColor(name, color),
            child: Text("Buy"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          ),
        if (isOwned)
          ElevatedButton(
            onPressed: () {
              setState(() {
                selectedColorName = name;
              });
              widget.onColorPurchased(color, 0, name); 
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$name color selected!')),
              );
            },
            child: Text("Use"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
      ],
    ),
  );
}
  Widget _buildPetItem(Pet pet) {
    return Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: pet.isAnimated
                ? Lottie.asset(pet.assetPath, width: 100, height: 100)
                : Image.asset(pet.assetPath, width: 100, height: 100),
          ),
          Text(pet.name, style: TextStyle(fontWeight: FontWeight.bold)),
          TextButton(
            onPressed: () {
              widget.onPetUse(pet.assetPath);
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.green,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text("Use"),
          ),
        ],
      ),
    );
  }
}
