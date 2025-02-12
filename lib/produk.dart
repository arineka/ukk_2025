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
    final supabase = Supabase.instance
        .client; // Mengakses instance Supabase untuk interaksi dengan database

    try {
      // Mengambil semua data dari tabel 'produk' dan mengurutkannya berdasarkan 'id_produk' secara ascending
      final List<Map<String, dynamic>> data = await supabase
          .from('produk')
          .select()
          .order('id_produk', ascending: true);

      setState(() {
        _produkList = data; // Menyimpan data produk ke dalam daftar utama
        _filteredProdukList = data; // Memastikan UI diperbarui setelah refresh
      });
    } catch (error) {
      print(
          'Error fetching data: $error'); // Menampilkan error jika terjadi masalah saat mengambil data
    }
  }

// Fungsi untuk menambahkan produk ke dalam database Supabase
  Future<void> _addProduk() async {
    final supabase = Supabase.instance.client; // Mengakses instance Supabase

    // Mengambil nilai input dari TextFormField
    final namaProduk =
        _namaProdukController.text.trim(); // Menghapus spasi di awal & akhir
    final harga = int.tryParse(_hargaController.text) ??
        0; // Konversi harga ke integer, default 0 jika tidak valid
    final stok = int.tryParse(_stokController.text) ??
        0; // Konversi stok ke integer, default 0 jika tidak valid

    // Validasi input: nama tidak boleh kosong, harga & stok harus lebih dari 0
    if (namaProduk.isEmpty || harga <= 0 || stok <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Pastikan semua field diisi dengan benar!'), // Pesan error untuk validasi input
          backgroundColor: Colors.red,
        ),
      );
      return; // Menghentikan eksekusi jika input tidak valid
    }

    try {
      // **Cek apakah nama produk sudah ada di database**
      final List<Map<String, dynamic>> existingProduk =
          await supabase.from('produk').select().eq('nama_produk', namaProduk);

      if (existingProduk.isNotEmpty) {
        // Jika produk dengan nama yang sama sudah ada
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Produk dengan nama ini sudah ada!'), // Pesan error jika produk sudah ada
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

      // Menampilkan pesan sukses setelah produk berhasil ditambahkan
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produk berhasil ditambahkan!'),
          backgroundColor: Colors.green,
        ),
      );

      _fetchProdukData(); // Memuat ulang data produk agar UI diperbarui
      _namaProdukController
          .clear(); // Mengosongkan input field setelah menambahkan produk
      _hargaController.clear();
      _stokController.clear();
      Navigator.pop(
          context); // Menutup dialog setelah berhasil menambahkan produk
    } catch (error) {
      print(
          'Error adding produk: $error'); // Menampilkan error jika terjadi kesalahan saat menambahkan produk
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
    final supabase = Supabase.instance
        .client; // Mengakses instance Supabase untuk berinteraksi dengan database

    // Menampilkan dialog konfirmasi sebelum menghapus produk
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Konfirmasi Hapus"), // Judul dialog
          content: const Text(
              "Apakah Anda yakin ingin menghapus produk ini?"), // Isi pesan konfirmasi
          actions: [
            // Tombol "Batal" untuk menutup dialog tanpa menghapus produk
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Menutup dialog konfirmasi
              },
              child: const Text("Batal"),
            ),
            // Tombol "Hapus" untuk menghapus produk
            TextButton(
              onPressed: () async {
                Navigator.pop(
                    context); // Menutup dialog sebelum proses penghapusan
                try {
                  // Menghapus produk dari database Supabase berdasarkan ID
                  await supabase.from('produk').delete().eq('id_produk', id);

                  // Menghapus produk dari daftar UI secara lokal agar tampilan diperbarui
                  setState(() {
                    _produkList
                        .removeWhere((produk) => produk['id_produk'] == id);
                    _filteredProdukList
                        .removeWhere((produk) => produk['id_produk'] == id);
                  });

                  // Menampilkan pesan sukses kepada pengguna setelah produk berhasil dihapus
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Produk berhasil dihapus.'), // Pesan sukses
                      backgroundColor: Colors
                          .green, // Warna latar belakang hijau menandakan sukses
                    ),
                  );
                } catch (error) {
                  // Menampilkan error di konsol jika terjadi masalah saat menghapus produk
                  print('Error deleting produk: $error');
                }
              },
              child: const Text("Hapus",
                  style: TextStyle(
                      color: Colors
                          .red)), // Teks tombol berwarna merah untuk indikasi tindakan berbahaya
            ),
          ],
        );
      },
    );
  }

  void _showAddProdukDialog() {
    // Membuat GlobalKey untuk mengelola status form
    final formKey = GlobalKey<FormState>();

    // Menampilkan dialog modal untuk menambahkan produk
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tambah Produk'), // Judul dialog
          content: Form(
            key: formKey, // Menggunakan formKey untuk validasi form
            child: Column(
              mainAxisSize:
                  MainAxisSize.min, // Menyesuaikan ukuran dialog dengan isi
              children: [
                // Input nama produk
                TextFormField(
                  controller: _namaProdukController, // Menghubungkan controller
                  decoration: const InputDecoration(labelText: 'Nama Produk'),
                  validator: (value) => value!.isEmpty
                      ? 'Nama Produk tidak boleh kosong'
                      : null, // Validasi agar tidak kosong
                ),
                // Input harga produk
                TextFormField(
                  controller: _hargaController, // Menghubungkan controller
                  keyboardType:
                      TextInputType.number, // Memastikan input berupa angka
                  decoration: const InputDecoration(labelText: 'Harga'),
                  validator: (value) => int.tryParse(value!) == null
                      ? 'Masukkan angka valid' // Validasi agar input berupa angka
                      : null,
                ),
                // Input stok produk
                TextFormField(
                  controller: _stokController, // Menghubungkan controller
                  keyboardType:
                      TextInputType.number, // Memastikan input berupa angka
                  decoration: const InputDecoration(labelText: 'Stok'),
                  validator: (value) => int.tryParse(value!) == null
                      ? 'Masukkan angka valid' // Validasi agar input berupa angka
                      : null,
                ),
              ],
            ),
          ),
          actions: [
            // Tombol Batal, menutup dialog tanpa menyimpan
            TextButton(
              onPressed: () => Navigator.pop(context), // Menutup dialog
              child: const Text('Batal'),
            ),
            // Tombol Simpan, memvalidasi dan menambah produk
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  // Jika form valid
                  _addProduk(); // Memanggil fungsi untuk menambahkan produk
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
    // Mencari produk dalam daftar berdasarkan ID yang dipilih
    final produk = _produkList.firstWhere((p) => p['id_produk'] == id);

    // Mengisi nilai controller dengan data produk yang akan diedit
    _namaProdukController.text = produk['nama_produk'];
    _hargaController.text = produk['harga'].toString();
    _stokController.text = produk['stok'].toString();

    // Menampilkan dialog untuk mengedit produk
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Produk'), // Judul dialog
          content: Form(
            key: _formKey, // Menggunakan GlobalKey untuk validasi form
            child: Column(
              mainAxisSize:
                  MainAxisSize.min, // Menyesuaikan ukuran dialog dengan isi
              children: [
                // Input nama produk
                TextFormField(
                  controller: _namaProdukController, // Menghubungkan controller
                  decoration: const InputDecoration(labelText: 'Nama Produk'),
                  validator: (value) => value!.isEmpty
                      ? 'Nama Produk tidak boleh kosong'
                      : null, // Validasi agar tidak kosong
                ),
                // Input harga produk
                TextFormField(
                  controller: _hargaController, // Menghubungkan controller
                  keyboardType:
                      TextInputType.number, // Memastikan input berupa angka
                  decoration: const InputDecoration(labelText: 'Harga'),
                  validator: (value) => int.tryParse(value!) == null
                      ? 'Masukkan angka valid' // Validasi agar input berupa angka
                      : null,
                ),
                // Input stok produk
                TextFormField(
                  controller: _stokController, // Menghubungkan controller
                  keyboardType:
                      TextInputType.number, // Memastikan input berupa angka
                  decoration: const InputDecoration(labelText: 'Stok'),
                  validator: (value) => int.tryParse(value!) == null
                      ? 'Masukkan angka valid' // Validasi agar input berupa angka
                      : null,
                ),
              ],
            ),
          ),
          actions: [
            // Tombol Batal, menutup dialog tanpa menyimpan perubahan
            TextButton(
              onPressed: () => Navigator.pop(context), // Menutup dialog
              child: const Text('Batal'),
            ),
            // Tombol Simpan, memvalidasi form lalu menyimpan perubahan
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // Jika form valid
                  _editProduk(
                      id); // Memanggil fungsi untuk mengupdate data produk
                  Navigator.pop(context); // Menutup dialog setelah menyimpan
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
      backgroundColor: const Color(0xFFF6F8FC), // Mengatur warna latar belakang
      body: Padding(
        padding: const EdgeInsets.all(
            16.0), // Memberikan padding pada seluruh konten
        child: Column(
          children: [
            // Input pencarian produk
            TextField(
              controller: _searchController, // Mengontrol input pencarian
              onChanged:
                  _searchProduk, // Memanggil fungsi pencarian saat teks berubah
              decoration: InputDecoration(
                labelText: 'Cari produk...', // Label input
                labelStyle: GoogleFonts.poppins(
                    fontSize: 16, color: Colors.grey), // Gaya teks label
                prefixIcon: const Icon(
                  Icons.search, // Ikon pencarian
                  color: Color(0xFF091057),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                      12), // Membuat border input membulat
                ),
              ),
            ),
            const SizedBox(
                height: 10), // Jarak antara input pencarian dan daftar produk

            // Daftar produk
            Expanded(
              child: _filteredProdukList.isEmpty
                  ? Center(
                      child: Text(
                        'Produk tidak ditemukan', // Pesan jika tidak ada produk yang ditemukan
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredProdukList
                          .length, // Jumlah produk yang ditampilkan
                      itemBuilder: (context, index) {
                        final produk = _filteredProdukList[
                            index]; // Mengambil data produk dari list
                        return Card(
                          margin: const EdgeInsets.only(
                              bottom: 10), // Memberikan jarak antar kartu
                          elevation: 2, // Menambahkan efek bayangan pada kartu
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                12), // Membuat kartu membulat
                          ),
                          child: ListTile(
                            contentPadding:
                                const EdgeInsets.all(12), // Padding dalam kartu
                            title: Text(
                              produk['nama_produk'], // Menampilkan nama produk
                              style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF091057)), // Gaya teks
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Harga: ${produk['harga']}', // Menampilkan harga produk
                                  style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: const Color(0xFFEC8305)),
                                ),
                                Text(
                                  'Stok: ${produk['stok']}', // Menampilkan stok produk
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: const Color(0xFF024CAA),
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize
                                  .min, // Mengatur ukuran agar lebih compact
                              children: [
                                // Tombol Edit Produk
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Color(0xFF091057)), // Ikon edit
                                  onPressed: () => _showEditProdukDialog(produk[
                                      'id_produk']), // Memanggil fungsi edit produk
                                ),
                                // Tombol Hapus Produk
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Color(0xFFF44336)), // Ikon hapus
                                  onPressed: () => _deleteProduk(produk[
                                      'id_produk']), // Memanggil fungsi hapus produk
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
      // Tombol FloatingActionButton untuk menambah produk baru
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProdukDialog, // Memanggil fungsi tambah produk
        backgroundColor: const Color(0xFF091057), // Warna tombol
        child: const Icon(Icons.add, color: Colors.white), // Ikon tambah
      ),
    );
  }
}
