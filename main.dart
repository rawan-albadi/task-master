import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'calendar_page.dart';
import 'login.dart';
import 'navbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'store_page.dart';
import 'WelcomePage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: const FirebaseOptions(
    apiKey: 'AIzaSyBN0Ok8eAptPK_Rwr6keft2yMQ3pJnulFw',
    appId: '1:297504993178:android:21b4e420300d20ac211423',
    messagingSenderId: '297504993178',
    projectId: 'project-efb0f',
  ));
  runApp(MaterialApp(
    
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
    ),
    home: WelcomePage(),
  ));
}

class Task {
  String title;
  DateTime createdDate;
  DateTime deadline;
  bool isDone;

  Task({
    required this.title,
    required this.createdDate,
    required this.deadline,
    this.isDone = false,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 1;
  List<Task> tasks = [];
  int coins = 0;
  Color backgroundColor = const Color.fromARGB(255, 255, 255, 255);
  List<String> purchasedBackgrounds = [];
  List<String> purchasedPets = [];
  String animalImage = "";
  final user = FirebaseAuth.instance.currentUser;
  final firestore = FirebaseFirestore.instance;
  void _updateCoins(int newCoins) {
    setState(() {
      coins = newCoins;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user != null) {
      final doc = await firestore.collection('users').doc(user!.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          coins = data['coins'] ?? 0;
          animalImage = data['animalImage'] ?? "";
          backgroundColor = Color(int.tryParse(data['backgroundColor'] ?? '0xFFFFFFFF') ?? 0xFFFFFFFF);
          purchasedBackgrounds = List<String>.from(data['purchasedBackgrounds'] ?? []);
          List<dynamic> tasksData = data['tasks'] ?? [];
          tasks = tasksData.map((taskData) {
            return Task(
              title: taskData['title'],
              createdDate: (taskData['createdDate'] as Timestamp).toDate(),
              deadline: (taskData['deadline'] as Timestamp).toDate(),
              isDone: taskData['isDone'] ?? false,
            );
          }).toList();
        });
      }
    }
  }

  Future<void> _saveUserData() async {
    if (user != null) {
      List<Map<String, dynamic>> tasksData = tasks.map((task) {
        return {
          'title': task.title,
          'createdDate': Timestamp.fromDate(task.createdDate),
          'deadline': Timestamp.fromDate(task.deadline),
          'isDone': task.isDone,
        };
      }).toList();

      await firestore.collection('users').doc(user!.uid).set({
        'coins': coins,
        'animalImage': animalImage,
        'backgroundColor': backgroundColor.value.toString(),
        'purchasedBackgrounds': purchasedBackgrounds,
        'tasks': tasksData,
      }, SetOptions(merge: true));
    }
  }

  void _addTask(String title, DateTime deadline) {
    setState(() {
      tasks.add(Task(
        title: title,
        createdDate: DateTime.now(),
        deadline: deadline,
      ));
    });
    _saveUserData();
  }
  void _editTask(Task task) {
  String editedTitle = task.title;
  DateTime editedDeadline = task.deadline;

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text("Edit Task"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: TextEditingController(text: editedTitle),
            onChanged: (value) {
              editedTitle = value;
            },
            decoration: InputDecoration(hintText: "Edit task title"),
          ),
          SizedBox(height: 10),
          TextButton(
            onPressed: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: editedDeadline,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              setState(() {
                if (picked != null) {
                  editedDeadline = picked;
                }
              });
              
                        },
            child: Text("Pick New Deadline"),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              task.title = editedTitle;
              task.deadline = editedDeadline;
            });
            _saveUserData();
            Navigator.pop(context);
          },
          child: Text("Save"),
        ),
      ],
    ),
  );
}


  void _showAddTaskDialog() {
    String newTask = "";
    DateTime selectedDeadline = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add Task"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              onChanged: (value) {
                newTask = value;
              },
              decoration: InputDecoration(hintText: "Add a new task..."),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                TextButton(
                  child: Text("Pick Deadline"),
                  onPressed: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDeadline,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    setState(() {
                      if (picked != null) {
                        selectedDeadline = picked;
                      }
                    });
                                    },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              if (newTask.trim().isNotEmpty) {
                _addTask(newTask.trim(), selectedDeadline);
              }
              Navigator.pop(context);
            },
            child: Text("Add"),
          ),
        ],
      ),
    );
  }

  List<Task> get todayTasks => tasks.where((t) {
        final now = DateTime.now();
        return !t.isDone &&
            t.createdDate.year == now.year &&
            t.createdDate.month == now.month &&
            t.createdDate.day == now.day;
      }).toList();

  List<Task> get completedTasks => tasks.where((t) => t.isDone).toList();

  List<Task> get pastTasks => tasks.where((t) {
        final now = DateTime.now();
        final isToday = t.createdDate.year == now.year &&
            t.createdDate.month == now.month &&
            t.createdDate.day == now.day;
        return !t.isDone && !isToday;
      }).toList();

  String formatDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Task Master',
        style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 36,
                  color: Color(0xFF512DA8), // Deep Purple 700
                  letterSpacing: 1.2,
                ),),
        centerTitle: true,
        backgroundColor:Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          Text("Coins: $coins", style: TextStyle(color: Colors.black)),
          Icon(Icons.monetization_on, color: Color(0xFFF6F609)),
          SizedBox(width: 20),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (animalImage.isNotEmpty)
                Center(
                  child: Lottie.asset(
                    animalImage,
                    width: 150,
                    height: 150,
                  ),
                ),
              Text("previous Tasks", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              if (pastTasks.isEmpty)
                Text("No previous tasks.")
              else
                Column(
                  children: pastTasks.map((task) {
                    return Card(
  child: ListTile(
    title: Text(task.title),
    subtitle: Text("Deadline: ${formatDate(task.deadline)}"),
    leading: Checkbox(
      value: task.isDone,
      onChanged: (value) {
        setState(() {
          task.isDone = value ?? false;
          if (task.isDone) {
            coins += (todayTasks.contains(task)) ? 15 : 10;
          }
          _saveUserData();
        });
      },
    ),
    trailing: PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'edit') {
          _editTask(task);
        } else if (value == 'delete') {
          setState(() {
            tasks.remove(task);
            _saveUserData();
          });
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Text('Edit'),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Text('Delete'),
        ),
      ],
    ),
  ),
);
                  }).toList(),
                ),
              SizedBox(height: 20),
              Text("Today", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              if (todayTasks.isEmpty)
                Text("No tasks for today.")
              else
                Column(
                  children: todayTasks.map((task) {
                    return Card(
  child: ListTile(
    title: Text(task.title),
    subtitle: Text("Deadline: ${formatDate(task.deadline)}"),
    leading: Checkbox(
      value: task.isDone,
      onChanged: (value) {
        setState(() {
          task.isDone = value ?? false;
          if (task.isDone) {
            coins += (todayTasks.contains(task)) ? 15 : 10;
          }
          _saveUserData();
        });
      },
    ),
    trailing: PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'edit') {
          _editTask(task);
        } else if (value == 'delete') {
          setState(() {
            tasks.remove(task);
            _saveUserData();
          });
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Text('Edit'),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Text('Delete'),
        ),
      ],
    ),
  ),
);

                  }).toList(),
                ),
              SizedBox(height: 20),
              Text("Completed ", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              if (completedTasks.isEmpty)
                Text("No completed tasks.")
              else
                Column(
                  children: completedTasks.map((task) {
                    return Card(
  child: ListTile(
    title: Text(
      task.title,
      style: TextStyle(decoration: TextDecoration.lineThrough),
    ),
    subtitle: Text("Deadline: ${formatDate(task.deadline)}"),
    leading: Icon(Icons.check_circle, color: Colors.green),
    trailing: IconButton(
      icon: Icon(Icons.delete, color: Colors.red),
      onPressed: () {
        setState(() {
          tasks.remove(task);
          _saveUserData();
        });
      },
    ),
  ),
);
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        backgroundColor: Color(0xFF512DA8), 
        child: Icon(Icons.add, color: Colors.white), 
      ),
      bottomNavigationBar: BottomNavigationBar(
         backgroundColor: const Color.fromARGB(255, 255, 255, 255), 
         selectedItemColor:Color(0xFF512DA8), 
         unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: (index) async {
          if(index==0){
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NavBar()),
            );

          }
          else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CalendarPage(tasks: tasks)),
            );
          } else if (index == 3) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => StorePage(
                points: coins,
                purchased: purchasedBackgrounds,
                selectedPet: animalImage,
                onColorPurchased: (Color newColor, int price, String title) {
                  backgroundColor = newColor;
                  coins -= price;
                  purchasedBackgrounds.add(title);
                  _saveUserData();
                },
                onPetPurchased: (String pet, int price) {
                  coins -= price;
                  purchasedPets.add(pet);
                  _saveUserData();
                },
                onPetUse: (String path) {
                  animalImage = path;
                  _saveUserData();
                },
                 onCoinsUpdated: _updateCoins, 
              )),
            );

            if (result != null && result is int) {
              setState(() {
                coins = result;
              });
              _saveUserData();
            }
          } else {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shop),
            label: 'Store',
          ),
        ],
      ),
    );
  }
}
