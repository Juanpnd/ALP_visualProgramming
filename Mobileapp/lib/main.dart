import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

// Constants
const String appTitle = 'Expense Tracker';
const String noExpensesMessage = 'No expenses logged yet!';
const String enterAmountPrompt = 'How much did you spend on';
const String saveDataButtonText = 'Save Expense';
const String amountLabelText = 'Amount in \$';
const String totalExpensesText = 'Total Expenses: \$';
const double cardMargin = 10.0;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          elevation: 2,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 16),
          bodyMedium: TextStyle(fontSize: 14),
        ),
      ),
      home: const MyHomePage(title: appTitle),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final CollectionReference expensesRef = FirebaseFirestore.instance.collection('expenses');
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _selectedIndex == 0 ? _buildHomePage() : _buildTrackerPage(),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.money),
            label: 'Expenses',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildDashboard(double totalExpenses) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard('Total', '\$${totalExpenses.toStringAsFixed(2)}', Colors.orange),
              _buildStatCard('Today', '\$50.00', Colors.green), // Example value for today
              _buildStatCard('Week', '\$350.00', Colors.blue),   // Example value for week
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHomePage() {
    return StreamBuilder(
      stream: expensesRef.snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final List<Map<String, dynamic>> expenses = snapshot.data!.docs.map((doc) {
          return doc.data() as Map<String, dynamic>;
        }).toList();

        double totalExpenses = expenses.fold(0, (sum, item) => sum + (item['amount'] as double));

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDashboard(totalExpenses),
              Text(
                '$totalExpensesText ${totalExpenses.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18),
              ),
              const Text(
                'Recent Expenses:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    return _buildExpenseCard(expense);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrackerPage() {
    return StreamBuilder(
      stream: expensesRef.snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var expenses = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>?; // Cast to Map and handle potential null
          return {
            'id': doc.id,
            'description': data?['description'] ?? 'No Description',
            'amount': data?['amount'] ?? 0.0,
            'category': data?['category'] ?? 'Other', // Default to 'Other' if category is missing
            'date': data?['date'] ?? 'Unknown Date',
          };
        }).toList();

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Expense Tracker',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    return _buildExpenseCard(expense);
                  },
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  _navigateToExpenseInput();
                },
                child: const Text('Add Expense'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpenseCard(Map<String, dynamic> expense) {
    Color getCategoryColor(String category) {
      switch (category) {
        case 'Food':
          return Colors.green;
        case 'Transport':
          return Colors.blue;
        case 'Utilities':
          return Colors.orange;
        case 'Entertainment':
          return Colors.purple;
        default:
          return Colors.grey;
      }
    }

    final Color backgroundColor = getCategoryColor(expense['category'] ?? 'Other');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: cardMargin, horizontal: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 5,
      color: backgroundColor.withOpacity(0.15),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: CircleAvatar(
          backgroundColor: backgroundColor,
          child: const Icon(Icons.attach_money, color: Colors.white),
        ),
        title: Text(
          expense['description'] ?? 'No Description',
          style: TextStyle(fontWeight: FontWeight.bold, color: backgroundColor),
        ),
        subtitle: Text(
          '${expense['category']} - \$${expense['amount']} on ${expense['date']}',
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.teal),
              onPressed: () {
                _navigateToExpenseInput(
                  expenseId: expense['id'],
                  description: expense['description'],
                  amount: expense['amount'],
                  category: expense['category'],
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                _confirmDelete(expense['id']);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String expenseId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text('Are you sure you want to delete this expense?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              expensesRef.doc(expenseId).delete();
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _navigateToExpenseInput({String? expenseId, String? description, double? amount, String? category}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExpenseInputScreen(
          expenseId: expenseId,
          initialDescription: description,
          initialAmount: amount,
          initialCategory: category,
          onSave: (String description, double amount, String category) {
            if (expenseId == null) {
              expensesRef.add({
                'description': description,
                'amount': amount,
                'category': category,
                'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
              });
            } else {
              expensesRef.doc(expenseId).update({
                'description': description,
                'amount': amount,
                'category': category,
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 3,
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class ExpenseInputScreen extends StatefulWidget {
  final String? expenseId;
  final String? initialDescription;
  final double? initialAmount;
  final String? initialCategory;
  final void Function(String, double, String) onSave;



  const ExpenseInputScreen({
    super.key,
    this.expenseId,
    this.initialDescription,
    this.initialAmount,
    this.initialCategory,
    required this.onSave,
  });

  @override
  _ExpenseInputScreenState createState() => _ExpenseInputScreenState();
}

class _ExpenseInputScreenState extends State<ExpenseInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String? _selectedCategory;

  final List<String> _categories = ['Food', 'Transport', 'Utilities', 'Entertainment'];

  @override
  void initState() {
    super.initState();
    _descriptionController.text = widget.initialDescription ?? '';
    _amountController.text = widget.initialAmount?.toString() ?? '';
    _selectedCategory = widget.initialCategory;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add/Edit Expense'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: amountLabelText),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                hint: const Text('Select Category'),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final description = _descriptionController.text;
                    final amount = double.parse(_amountController.text);
                    widget.onSave(description, amount, _selectedCategory!);
                    Navigator.pop(context);
                  }
                },
                child: const Text(saveDataButtonText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
