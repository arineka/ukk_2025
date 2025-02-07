import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  // int _selectedIndex = 3;
  List<Map<String, dynamic>> _pelangganList = [];
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _noTlpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPelangganData();
  }

  Future<void> _fetchPelangganData() async {
    final supabase = Supabase.instance.client;

    try {
      final List<Map<String, dynamic>> data = await supabase
          .from('pelanggan')
          .select()
          .order('id_pelanggan', ascending: true);

      setState(() {
        _pelangganList = data;
      });
    } catch (error) {
      print('Error fetching data: $error');
    }
  }

  Future<void> _deletePelanggan(int id) async {
    final supabase = Supabase.instance.client;

    try {
      // Ubah semua transaksi pelanggan ini menjadi NULL sebelum dihapus
      await supabase
          .from('penjualan')
          .update({'pelanggan_id': null}).eq('pelanggan_id', id);

      // Hapus pelanggan setelah transaksi diperbarui
      await supabase.from('pelanggan').delete().eq('id_pelanggan', id);

      setState(() {
        _pelangganList
            .removeWhere((pelanggan) => pelanggan['id_pelanggan'] == id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pelanggan berhasil dihapus.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      print('Error deleting pelanggan: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menghapus pelanggan!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addPelanggan() async {
    final supabase = Supabase.instance.client;

    // Ambil data dari form
    final nama = _namaController.text;
    final alamat = _alamatController.text;
    final noTlp = _noTlpController.text;

    print(
        'Nama: $nama, Alamat: $alamat, No Telepon: $noTlp'); // Debugging statement

    if (nama.isNotEmpty && alamat.isNotEmpty && noTlp.isNotEmpty) {
      try {
        // Insert data pelanggan baru ke database
        await supabase.from('pelanggan').insert({
          'nama_pelanggan': nama,
          'alamat': alamat,
          'no_tlp': noTlp,
        });

        // Perbarui tampilan setelah penambahan
        _fetchPelangganData();

        // Reset form input
        _namaController.clear();
        _alamatController.clear();
        _noTlpController.clear();

        // Tutup form
        Navigator.pop(context);
      } catch (error) {
        print('Error adding pelanggan: $error');
      }
    } else {
      print('Field tidak boleh kosong!');
    }
  }

  Future<void> _editPelanggan(int id) async {
    final supabase = Supabase.instance.client;

    // Ambil data dari form
    final nama = _namaController.text;
    final alamat = _alamatController.text;
    final noTlp = _noTlpController.text;

    if (nama.isNotEmpty && alamat.isNotEmpty && noTlp.isNotEmpty) {
      try {
        // Update data pelanggan di database
        await supabase.from('pelanggan').update({
          'nama_pelanggan': nama,
          'alamat': alamat,
          'no_tlp': noTlp,
        }).eq('id_pelanggan', id);

        // Perbarui tampilan setelah pembaruan
        _fetchPelangganData();

        // Reset form input
        _namaController.clear();
        _alamatController.clear();
        _noTlpController.clear();

        // Tutup form
        Navigator.pop(context);
      } catch (error) {
        print('Error editing pelanggan: $error');
      }
    } else {
      print('Field tidak boleh kosong!');
    }
  }

  // void _logout() {
  //   Navigator.pushReplacement(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => const Lo(),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Daftar User',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
            color: Color(0xFF074799),
          ),
        ),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.logout_rounded),
        //     color: const Color(0xFF074799),
        //     onPressed: _logout,
        //   ),
        // ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _pelangganList.isEmpty
                ? const Expanded(
                    child: Center(
                      child: Text(
                        'Belum ada User',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Poppins',
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                : Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(0),
                      itemCount: _pelangganList.length,
                      itemBuilder: (context, index) {
                        final pelanggan = _pelangganList[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            title: Text(
                              pelanggan['nama_pelanggan'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Alamat: ${pelanggan['alamat']}',
                                    style:
                                        const TextStyle(fontFamily: 'Poppins')),
                                Text('No. Telepon: ${pelanggan['no_tlp']}',
                                    style:
                                        const TextStyle(fontFamily: 'Poppins')),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blue),
                                  onPressed: () {
                                    _showEditPelangganDialog(pelanggan);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _deletePelanggan(
                                      pelanggan['id_pelanggan']),
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
      // bottomNavigationBar: BottomNavBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPelangganDialog,
        child: const Icon(Icons.add, color: Colors.white),
        backgroundColor: const Color(0xFF074799),
      ),
    );
  }

  void _showAddPelangganDialog() {
    final _formKey =
        GlobalKey<FormState>(); // Tambahkan GlobalKey untuk validasi

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tambah Pelanggan'),
          content: Form(
            key: _formKey, // Gunakan form key
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _namaController,
                  decoration:
                      const InputDecoration(labelText: 'Nama Pelanggan'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama pelanggan tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _alamatController,
                  decoration: const InputDecoration(labelText: 'Alamat'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Alamat tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _noTlpController,
                  decoration: const InputDecoration(labelText: 'No. Telepon'),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'No. telepon tidak boleh kosong';
                    } else if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                      return 'No. telepon harus berupa angka';
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
                  _addPelanggan();
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _showEditPelangganDialog(Map<String, dynamic> pelanggan) {
    final _formKey = GlobalKey<FormState>();

    _namaController.text = pelanggan['nama_pelanggan'];
    _alamatController.text = pelanggan['alamat'];
    _noTlpController.text = pelanggan['no_tlp'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Pelanggan'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _namaController,
                  decoration:
                      const InputDecoration(labelText: 'Nama Pelanggan'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama pelanggan tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _alamatController,
                  decoration: const InputDecoration(labelText: 'Alamat'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Alamat tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _noTlpController,
                  decoration: const InputDecoration(labelText: 'No. Telepon'),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'No. telepon tidak boleh kosong';
                    } else if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                      return 'No. telepon harus berupa angka';
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
                  _editPelanggan(pelanggan['id_pelanggan']);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

}

