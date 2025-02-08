import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Produk extends StatefulWidget {
  const Produk({super.key});

  @override
  State<Produk> createState() => _ProdukState();
}

class _ProdukState extends State<Produk> {
  List<Map<String, dynamic>> _produkList = [];
  final TextEditingController _namaProdukController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();
  final TextEditingController _stokController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _fetchProdukData();
  }

  Future<void> _fetchProdukData() async {
    final supabase = Supabase.instance.client;

    try {
      final List<Map<String, dynamic>> data = await supabase
          .from('produk')
          .select()
          .order('id_produk', ascending: true);

      setState(() {
        _produkList = data;
      });
    } catch (error) {
      print('Error fetching data: $error');
    }
  }

  Future<void> _addProduk() async {
    final supabase = Supabase.instance.client;

    final namaProduk = _namaProdukController.text;
    final harga = int.tryParse(_hargaController.text) ?? 0;
    final stok = int.tryParse(_stokController.text) ?? 0;

    if (namaProduk.isEmpty || harga <= 0 || stok <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pastikan semua field diisi dengan benar!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await supabase.from('produk').insert({
        'nama_produk': namaProduk,
        'harga': harga,
        'stok': stok,
      });

      _fetchProdukData();

      _namaProdukController.clear();
      _hargaController.clear();
      _stokController.clear();

      Navigator.pop(context);
    } catch (error) {
      print('Error adding produk: $error');
    }
  }

  Future<void> _editProduk(int id) async {
    final supabase = Supabase.instance.client;
    final namaProduk = _namaProdukController.text.trim();
    final harga = int.tryParse(_hargaController.text) ?? 0;
    final stokBaru = int.tryParse(_stokController.text) ?? 0;

    if (namaProduk.isEmpty || harga <= 0 || stokBaru < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pastikan semua field diisi dengan benar!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final produk = _produkList.firstWhere((p) => p['id_produk'] == id);
    final stokTersedia = produk['stok'];

    if (stokBaru > stokTersedia) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stok tidak cukup! Stok tersedia: $stokTersedia'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await supabase.from('produk').update({
        'nama_produk': namaProduk,
        'harga': harga,
        'stok': stokBaru,
      }).eq('id_produk', id);

      _fetchProdukData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produk berhasil diperbarui!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      print('Error updating produk: $error');
    }
  }

  Future<void> _deleteProduk(int id) async {
    final supabase = Supabase.instance.client;

    try {
      await supabase.from('produk').delete().eq('id_produk', id);

      setState(() {
        _produkList.removeWhere((produk) => produk['id_produk'] == id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produk berhasil dihapus.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      print('Error deleting produk: $error');
    }
  }

  void _showAddProdukDialog() {
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tambah Produk'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _namaProdukController,
                  decoration: const InputDecoration(labelText: 'Nama Produk'),
                  validator: (value) =>
                      value!.isEmpty ? 'Nama Produk tidak boleh kosong' : null,
                ),
                TextFormField(
                  controller: _hargaController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Harga'),
                  validator: (value) =>
                      int.tryParse(value!) == null ? 'Masukkan angka valid' : null,
                ),
                TextFormField(
                  controller: _stokController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stok'),
                  validator: (value) =>
                      int.tryParse(value!) == null ? 'Masukkan angka valid' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  _addProduk();
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _showEditProdukDialog(int id) {
    final produk = _produkList.firstWhere((p) => p['id_produk'] == id);

    _namaProdukController.text = produk['nama_produk'];
    _hargaController.text = produk['harga'].toString();
    _stokController.text = produk['stok'].toString();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Produk'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _namaProdukController,
                  decoration: const InputDecoration(labelText: 'Nama Produk'),
                  validator: (value) =>
                      value!.isEmpty ? 'Nama Produk tidak boleh kosong' : null,
                ),
                TextFormField(
                  controller: _hargaController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Harga'),
                  validator: (value) =>
                      int.tryParse(value!) == null ? 'Masukkan angka valid' : null,
                ),
                TextFormField(
                  controller: _stokController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stok'),
                  validator: (value) {
                    final stokBaru = int.tryParse(value!) ?? 0;
                    if (stokBaru > produk['stok']) {
                      return 'Stok tidak boleh lebih dari ${produk['stok']}';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _editProduk(id);
                  Navigator.pop(context);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFF6F8FC),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: _produkList.isEmpty
          ? const Center(
              child: Text(
                'Belum ada Produk',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Poppins',
                  color: Colors.grey,
                ),
              ),
            )
          : ListView.builder(
              itemCount: _produkList.length,
              itemBuilder: (context, index) {
                final produk = _produkList[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    title: Text(
                      produk['nama_produk'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Harga: ${produk['harga']}',
                          style: const TextStyle(fontFamily: 'Poppins'),
                        ),
                        Text(
                          'Stok: ${produk['stok']}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () =>
                              _showEditProdukDialog(produk['id_produk']),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteProduk(produk['id_produk']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: _showAddProdukDialog,
      child: const Icon(Icons.add, color: Colors.white),
      backgroundColor: const Color(0xFF074799),
    ),
  );
}

}
