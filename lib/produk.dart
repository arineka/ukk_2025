import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class Produk extends StatefulWidget {
  const Produk({super.key});

  @override
  State<Produk> createState() => _ProdukState();
}

// State untuk widget Produk
class _ProdukState extends State<Produk> {
  // List untuk menyimpan data produk yang diambil dari Supabase
  List<Map<String, dynamic>> _produkList = [];
  List<Map<String, dynamic>> _filteredProdukList = [];

  // Controller untuk menangani input pada form
  final TextEditingController _searchController =
      TextEditingController(); // Controller untuk search
  final TextEditingController _namaProdukController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();
  final TextEditingController _stokController = TextEditingController();

  // key untuk validasi form
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _fetchProdukData(); //fungsi untuk memanggil data produk yang dibuat
  }

  void _searchProduk(String query) {
    setState(() {
      _filteredProdukList = _produkList
          .where((produk) =>
              produk['nama_produk'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  // Fungsi untuk mengambil data produk dari database Supabase
  Future<void> _fetchProdukData() async {
    final supabase = Supabase.instance.client;

    try {
      final List<Map<String, dynamic>> data = await supabase
          .from('produk')
          .select()
          .order('id_produk', ascending: true);

      setState(() {
        _produkList = data;
        _filteredProdukList = data; // Memastikan UI diperbarui setelah refresh
      });
    } catch (error) {
      print('Error fetching data: $error');
    }
  }

// Fungsi untuk menambahkan produk ke dalam database Supabase
  Future<void> _addProduk() async {
    final supabase = Supabase.instance.client;

    final namaProduk = _namaProdukController.text.trim();
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
      // **Cek apakah nama produk sudah ada di database**
      final List<Map<String, dynamic>> existingProduk =
          await supabase.from('produk').select().eq('nama_produk', namaProduk);

      if (existingProduk.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produk dengan nama ini sudah ada!'),
            backgroundColor: Colors.red,
          ),
        );
        return; // **Hentikan proses insert jika produk sudah ada**
      }

      // Jika produk belum ada, tambahkan ke database
      await supabase.from('produk').insert({
        'nama_produk': namaProduk,
        'harga': harga,
        'stok': stok,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produk berhasil ditambahkan!'),
          backgroundColor: Colors.green,
        ),
      );

      _fetchProdukData();
      _namaProdukController.clear();
      _hargaController.clear();
      _stokController.clear();
      Navigator.pop(context);
    } catch (error) {
      print('Error adding produk: $error');
    }
  }

  // Fungsi untuk mengedit data produk berdasarkan ID
  Future<void> _editProduk(int id) async {
    final supabase = Supabase.instance.client; // Mengakses instance Supabase

    // Mengambil nilai dari input pengguna dan memastikan tidak ada spasi berlebih
    final namaProduk = _namaProdukController.text.trim();
    final harga = int.tryParse(_hargaController.text) ?? 0;
    final stokBaru = int.tryParse(_stokController.text) ?? 0;

    // Validasi input: Pastikan semua field diisi dengan benar
    if (namaProduk.isEmpty || harga <= 0 || stokBaru < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pastikan semua field diisi dengan benar!'),
          backgroundColor: Colors.red,
        ),
      );
      return; // Menghentikan proses jika input tidak valid
    }

    try {
      // Melakukan update data produk berdasarkan ID yang diberikan
      await supabase.from('produk').update({
        'nama_produk': namaProduk,
        'harga': harga,
        'stok': stokBaru, // Sekarang stok bisa diperbarui bebas
      }).eq('id_produk', id);

      // Memanggil kembali fungsi _fetchProdukData untuk memperbarui daftar produk
      _fetchProdukData();

      // Menampilkan pesan sukses kepada pengguna
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produk berhasil diperbarui!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      // Menampilkan error jika gagal memperbarui produk
      print('Error updating produk: $error');
    }
  }

  // Fungsi untuk menghapus produk berdasarkan ID dengan konfirmasi
  Future<void> _deleteProduk(int id) async {
    final supabase = Supabase.instance.client; // Mengakses instance Supabase

    // Menampilkan dialog konfirmasi sebelum menghapus
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Konfirmasi Hapus"),
          content: const Text("Apakah Anda yakin ingin menghapus produk ini?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Tutup dialog tanpa menghapus
              },
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Tutup dialog sebelum menghapus
                try {
                  // Menghapus produk dari database Supabase berdasarkan ID
                  await supabase.from('produk').delete().eq('id_produk', id);

                  // Menghapus produk dari daftar UI secara lokal
                  setState(() {
                    _produkList
                        .removeWhere((produk) => produk['id_produk'] == id);
                    _filteredProdukList
                        .removeWhere((produk) => produk['id_produk'] == id);
                  });

                  // Menampilkan pesan sukses kepada pengguna
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Produk berhasil dihapus.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (error) {
                  print('Error deleting produk: $error');
                }
              },
              child: const Text("Hapus", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
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
                  validator: (value) => int.tryParse(value!) == null
                      ? 'Masukkan angka valid'
                      : null,
                ),
                TextFormField(
                  controller: _stokController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stok'),
                  validator: (value) => int.tryParse(value!) == null
                      ? 'Masukkan angka valid'
                      : null,
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
                  validator: (value) => int.tryParse(value!) == null
                      ? 'Masukkan angka valid'
                      : null,
                ),
                TextFormField(
                  controller: _stokController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stok'),
                  validator: (value) => int.tryParse(value!) == null
                      ? 'Masukkan angka valid'
                      : null,
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
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: _searchProduk,
              decoration: InputDecoration(
                labelText: 'Cari Produk',
                labelStyle:
                    GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF091057),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _filteredProdukList.isEmpty
                  ? Center(
                      child: Text(
                        'Produk tidak ditemukan',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredProdukList.length,
                      itemBuilder: (context, index) {
                        final produk = _filteredProdukList[index];
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
                              style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF091057)),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Harga: ${produk['harga']}',
                                  style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: const Color(0xFFEC8305)),
                                ),
                                Text(
                                  'Stok: ${produk['stok']}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: const Color(0xFF024CAA),
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Color(0xFF091057)),
                                  onPressed: () => _showEditProdukDialog(
                                      produk['id_produk']),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Color(0xFFF44336)),
                                  onPressed: () =>
                                      _deleteProduk(produk['id_produk']),
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
        onPressed: _showAddProdukDialog,
        backgroundColor: const Color(0xFF091057),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
