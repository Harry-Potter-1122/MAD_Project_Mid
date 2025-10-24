import 'package:flutter/material.dart';

void main() {
  runApp(MadProjectApp());
}

class MadProjectApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MAD Project',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.grey.shade100,
      ),
      home: MainScreen(),
    );
  }
}

// =================== MAIN SCREEN (Bottom Navigation) ===================
class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  double ratePerUnit = 30.0;
  List<String> homes = ["Home-1"];
  String selectedHome = "Home-1";
  Map<String, List<Map<String, dynamic>>> homeDevices = {};

  @override
  void initState() {
    super.initState();
    homeDevices[selectedHome] = [];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> _screens = [
      HomeScreen(
        homes: homes,
        onAddHome: () {
          setState(() {
            homes.add("Home-${homes.length + 1}");
            homeDevices["Home-${homes.length}"] = [];
          });
        },
        onDeleteHome: (index) {
          setState(() {
            homeDevices.remove(homes[index]);
            homes.removeAt(index);
          });
        },
        onSelectHome: (homeName) {
          setState(() {
            selectedHome = homeName;
            if (!homeDevices.containsKey(homeName)) {
              homeDevices[homeName] = [];
            }
            _selectedIndex = 1;
          });
        },
      ),
      DevicesScreen(
        homeName: selectedHome,
        items: homeDevices[selectedHome] ?? [],
        onAddItem: (item) {
          setState(() {
            homeDevices[selectedHome]!.add(item);
          });
        },
        onDeleteItem: (index) {
          setState(() {
            homeDevices[selectedHome]!.removeAt(index);
          });
        },
        ratePerUnit: ratePerUnit,
      ),
      SettingsScreen(
        ratePerUnit: ratePerUnit,
        onRateChanged: (newRate) {
          setState(() {
            ratePerUnit = newRate;
          });
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Electricity Tracker'),
        backgroundColor: Colors.blueAccent,
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.electric_bolt),
            label: 'Devices',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// =================== HOME SCREEN ===================
class HomeScreen extends StatelessWidget {
  final List<String> homes;
  final VoidCallback onAddHome;
  final Function(int) onDeleteHome;
  final Function(String) onSelectHome;

  HomeScreen({
    required this.homes,
    required this.onAddHome,
    required this.onDeleteHome,
    required this.onSelectHome,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: homes.isEmpty
          ? Center(child: Text("No homes added yet."))
          : ListView.builder(
        padding: EdgeInsets.all(12),
        itemCount: homes.length,
        itemBuilder: (context, index) {
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
            margin: EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blueAccent.shade100,
                child: Icon(Icons.home, color: Colors.blueAccent),
              ),
              title: Text(homes[index],
                  style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () => onDeleteHome(index),
              ),
              onTap: () => onSelectHome(homes[index]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onAddHome,
        label: Text("Add Home"),
        icon: Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }
}

// =================== DEVICES SCREEN ===================
class DevicesScreen extends StatelessWidget {
  final String homeName;
  final List<Map<String, dynamic>> items;
  final Function(Map<String, dynamic>) onAddItem;
  final Function(int) onDeleteItem;
  final double ratePerUnit;

  DevicesScreen({
    required this.homeName,
    required this.items,
    required this.onAddItem,
    required this.onDeleteItem,
    required this.ratePerUnit,
  });

  void _showAddItemDialog(BuildContext context) {
    String name = '';
    double watts = 0;
    double hours = 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add Electric Item"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(labelText: "Item Name"),
              onChanged: (value) => name = value,
            ),
            TextField(
              decoration: InputDecoration(labelText: "Power (Watts)"),
              keyboardType: TextInputType.number,
              onChanged: (value) => watts = double.tryParse(value) ?? 0,
            ),
            TextField(
              decoration: InputDecoration(labelText: "Hours per day"),
              keyboardType: TextInputType.number,
              onChanged: (value) => hours = double.tryParse(value) ?? 0,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (name.isNotEmpty && watts > 0 && hours > 0) {
                onAddItem({
                  'name': name,
                  'watts': watts,
                  'hours': hours,
                });
                Navigator.pop(context);
              }
            },
            child: Text("Add"),
          ),
        ],
      ),
    );
  }

  double _calculateMonthlyCost() {
    double totalKwh = 0;
    for (var item in items) {
      totalKwh += (item['watts'] * item['hours'] * 30) / 1000;
    }
    return totalKwh * ratePerUnit;
  }

  @override
  Widget build(BuildContext context) {
    double totalBill = _calculateMonthlyCost();

    return Scaffold(
      body: items.isEmpty
          ? Center(child: Text("No items added yet for $homeName"))
          : ListView.builder(
        padding: EdgeInsets.all(12),
        itemCount: items.length,
        itemBuilder: (context, index) {
          var item = items[index];
          double monthlyKwh =
              (item['watts'] * item['hours'] * 30) / 1000;
          double cost = monthlyKwh * ratePerUnit;

          return Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            margin: EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.teal.shade100,
                child: Icon(Icons.electric_bolt, color: Colors.teal),
              ),
              title: Text(item['name'],
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                  '${item['watts']}W, ${item['hours']}h/day\nMonthly: ${monthlyKwh.toStringAsFixed(2)} kWh'),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () => onDeleteItem(index),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16),
        color: Colors.teal.shade50,
        child: Text(
          'Total Monthly Bill for $homeName: Rs. ${totalBill.toStringAsFixed(2)}',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemDialog(context),
        label: Text("Add Item"),
        icon: Icon(Icons.add),
        backgroundColor: Colors.teal,
      ),
    );
  }
}

// =================== SETTINGS SCREEN ===================
class SettingsScreen extends StatelessWidget {
  final double ratePerUnit;
  final Function(double) onRateChanged;

  SettingsScreen({required this.ratePerUnit, required this.onRateChanged});

  @override
  Widget build(BuildContext context) {
    TextEditingController rateController =
    TextEditingController(text: ratePerUnit.toString());

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text("Electricity Rate (Rs. per kWh)",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(
              controller: rateController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(hintText: "e.g. 30"),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                double newRate =
                    double.tryParse(rateController.text) ?? ratePerUnit;
                onRateChanged(newRate);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Rate updated successfully")),
                );
              },
              icon: Icon(Icons.save),
              label: Text("Save"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            ),
          ],
        ),
      ),
    );
  }
}
