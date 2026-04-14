import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'الحوشاب داتا',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.home_work, size: 100, color: Colors.green),
            const Text("الحوشاب داتا", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "البريد الإلكتروني", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "كلمة المرور", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.signInWithEmailAndPassword(
                    email: emailController.text.trim(),
                    password: passwordController.text.trim(),
                  );
                  if (mounted) {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("خطأ في تسجيل الدخول")));
                  }
                }
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text("دخول"),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("بيانات أهالي الحوشاب"), centerTitle: true),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditScreen())),
        child: const Icon(Icons.person_add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: const InputDecoration(hintText: "ابحث بالاسم أو الهاتف...", prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
              onChanged: (value) => setState(() => searchQuery = value.trim()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('families').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                var docs = snapshot.data!.docs.where((doc) {
                  final name = doc['name'].toString().toLowerCase();
                  return name.contains(searchQuery.toLowerCase());
                }).toList();

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(data['name'] ?? ''),
                        subtitle: Text("الحي: ${data['area']} | هاتف: ${data['phone']}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditScreen(doc: data))),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => data.reference.delete(),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AddEditScreen extends StatefulWidget {
  final DocumentSnapshot? doc;
  const AddEditScreen({super.key, this.doc});

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final nationalId = TextEditingController();
  String selectedArea = "الثورة";

  @override
  void initState() {
    super.initState();
    if (widget.doc != null) {
      name.text = widget.doc!['name'] ?? '';
      phone.text = widget.doc!['phone'] ?? '';
      nationalId.text = widget.doc!['national_id'] ?? '';
      selectedArea = widget.doc!['area'] ?? "الثورة";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.doc == null ? "إضافة مواطن" : "تعديل بيانات")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: "الاسم الكامل")),
            const SizedBox(height: 10),
            TextField(controller: nationalId, decoration: const InputDecoration(labelText: "الرقم الوطني"), keyboardType: TextInputType.number),
            const SizedBox(height: 10),
            TextField(controller: phone, decoration: const InputDecoration(labelText: "رقم الهاتف"), keyboardType: TextInputType.phone),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: selectedArea,
              decoration: const InputDecoration(labelText: "الحي"),
              items: ["الثورة", "القلعة", "الواجهة", "الصهريج"]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => selectedArea = v!),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                if (name.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("يرجى إدخال الاسم")));
                  return;
                }
                final data = {
                  'name': name.text,
                  'national_id': nationalId.text,
                  'phone': phone.text,
                  'area': selectedArea,
                };
                if (widget.doc == null) {
                  await FirebaseFirestore.instance.collection('families').add(data);
                } else {
                  await widget.doc!.reference.update(data);
                }
                if (mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text("حفظ البيانات"),
            ),
          ],
        ),
      ),
    );
  }
}
