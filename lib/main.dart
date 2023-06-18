import 'package:flutter/material.dart';
import 'checklist_item.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();
  runApp(ChecklistApp());
}

class ChecklistApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Check-list',
      theme: ThemeData(
        primarySwatch: MaterialColor(
          0xFF4CAF50,
          <int, Color>{
            50: Color(0xFFE8F5E9),
            100: Color(0xFFC8E6C9),
            200: Color(0xFFA5D6A7),
            300: Color(0xFF81C784),
            400: Color(0xFF66BB6A),
            500: Color(0xFF4CAF50),
            600: Color(0xFF43A047),
            700: Color(0xFF388E3C),
            800: Color(0xFF2E7D32),
            900: Color(0xFF1B5E20),
          },
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ChecklistScreen(),
    );
  }
}

class ChecklistScreen extends StatefulWidget {
  @override
  _ChecklistScreenState createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  List<ChecklistItem> checklistItems = [];
  TextEditingController taskController = TextEditingController();
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    loadChecklistItems();
  }

  Future<void> loadChecklistItems() async {
    _prefs = await SharedPreferences.getInstance();
    final storedItems = _prefs!.getStringList('checklistItems');
    if (storedItems != null) {
      setState(() {
        checklistItems = storedItems
            .map((item) {
              final parts = item.split(':');
              return ChecklistItem(
                id: parts[0],
                title: parts[1],
                isChecked: parts[2] == 'true',
              );
            })
            .toList();
      });
    }
  }

  Future<void> saveChecklistItems() async {
    final itemsToStore = checklistItems
        .map((item) => '${item.id}:${item.title}:${item.isChecked}')
        .toList();
    await _prefs!.setStringList('checklistItems', itemsToStore);
  }

  void _addTask() {
    if (taskController.text.isNotEmpty) {
      setState(() {
        final newItem = ChecklistItem(
          id: uuid.v4(),
          title: taskController.text,
        );
        checklistItems.add(newItem);
        taskController.clear();
        saveChecklistItems();
      });
    }
  }

  void _toggleCheck(String id) {
    final index = checklistItems.indexWhere((item) => item.id == id);
    if (index != -1) {
      setState(() {
        checklistItems[index].isChecked = !checklistItems[index].isChecked;
        saveChecklistItems();
      });
    }
  }

  void _removeCompletedTasks() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmation'),
        content: Text(
          'Are you sure you want to remove completed tasks?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                checklistItems.removeWhere((item) => item.isChecked);
                saveChecklistItems();
                Navigator.pop(context);
              });
            },
            child: Text('Remove'),
          ),
        ],
      ),
    );
  }

  final uuid = Uuid();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Checklist'),
      ),
      body: checklistItems.isEmpty
          ? Center(
              child: Text(
                'Congratulations! You have no pending tasks.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            )
          : ReorderableListView(
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                setState(() {
                  final item = checklistItems.removeAt(oldIndex);
                  checklistItems.insert(newIndex, item);
                  saveChecklistItems();
                });
              },
              children: [
                for (final item in checklistItems)
                  Column(
                    key: Key(item.id),
                    children: [
                      ListTile(
                        title: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 18,
                            decoration: item.isChecked
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                        leading: Checkbox(
                          value: item.isChecked,
                          onChanged: (value) => _toggleCheck(item.id),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Confirmation'),
                                content: Text(
                                  'Are you sure you want to delete this task?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        checklistItems.removeWhere(
                                            (element) => element.id == item.id);
                                        saveChecklistItems();
                                        Navigator.pop(context);
                                      });
                                    },
                                    child: Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      Divider(),
                    ],
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('Add Task'),
                content: TextField(
                  controller: taskController,
                  decoration: InputDecoration(
                    hintText: 'Enter task name',
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _addTask();
                    },
                    child: Text('Add'),
                  ),
                ],
              );
            },
          );
        },
        child: Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      persistentFooterButtons: checklistItems.isNotEmpty
          ? [
              ElevatedButton(
                onPressed: _removeCompletedTasks,
                child: Text('Remove completed tasks'),
              ),
            ]
          : null,
    );
  }
}
