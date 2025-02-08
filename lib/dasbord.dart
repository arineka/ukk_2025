import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  List<Map<String, dynamic>> _userList = [];
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  /// 🔹 Ambil Data User dari Supabase
  Future<void> _fetchUserData() async {
    final supabase = Supabase.instance.client;

    try {
      final List<Map<String, dynamic>> data = await supabase
          .from('user')
          .select()
          .order('id_user', ascending: true);

      setState(() {
        _userList = data;
      });
    } catch (error) {
      print('Error fetching data: $error');
    }
  }

  /// 🔹 Hapus User dari Database
  Future<void> _deleteUser(int id) async {
    final supabase = Supabase.instance.client;

    try {
      await supabase.from('user').delete().eq('id_user', id);

      setState(() {
        _userList.removeWhere((user) => user['id_user'] == id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User berhasil dihapus.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      print('Error deleting user: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menghapus user!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 🔹 Tambah User Baru ke Supabase
  Future<void> _addUser() async {
    final supabase = Supabase.instance.client;

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isNotEmpty && password.isNotEmpty) {
      try {
        await supabase.from('user').insert({
          'username': username,
          'password': password,
        });

        _fetchUserData();

        _usernameController.clear();
        _passwordController.clear();

        Navigator.pop(context);
      } catch (error) {
        print('Error adding user: $error');
      }
    } else {
      print('Username dan password tidak boleh kosong!');
    }
  }

  /// 🔹 Edit User di Supabase
  Future<void> _editUser(int id) async {
    final supabase = Supabase.instance.client;

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isNotEmpty && password.isNotEmpty) {
      try {
        await supabase.from('user').update({
          'username': username,
          'password': password,
        }).eq('id_user', id);

        _fetchUserData();

        _usernameController.clear();
        _passwordController.clear();

        Navigator.pop(context);
      } catch (error) {
        print('Error editing user: $error');
      }
    } else {
      print('Username dan password tidak boleh kosong!');
    }
  }

  /// 🔹 Form Tambah User
  void _showAddUserDialog() {
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tambah User'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Username tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Password tidak boleh kosong';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _addUser();
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  /// 🔹 Form Edit User
  void _showEditUserDialog(Map<String, dynamic> user) {
    final _formKey = GlobalKey<FormState>();

    _usernameController.text = user['username'] ?? '';
    _passwordController.text = user['password'] ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit User'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Username tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Password tidak boleh kosong';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _editUser(user['id_user']);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  /// 🔹 UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _userList.length,
                itemBuilder: (context, index) {
                  final user = _userList[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(user['username']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              _showEditUserDialog(user);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteUser(user['id_user']),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        child: const Icon(Icons.add, color: Colors.white),
        backgroundColor: const Color(0xFF074799),
      ),
    );
  }
}

