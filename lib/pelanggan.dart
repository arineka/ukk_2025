import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class Pelanggan extends StatefulWidget {
  const Pelanggan({super.key});

  @override
  State<Pelanggan> createState() => _PelangganState();
}

class _PelangganState extends State<Pelanggan> {
  List<Map<String, dynamic>> _pelangganList = [];
  List<Map<String, dynamic>> _filteredPelangganList = [];
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _namaPelangganController =
      TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _noTlpController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _fetchPelangganData();
    _searchController.addListener(() {
      setState(() {
        _filterPelanggan();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPelangganData() async {
    final supabase = Supabase.instance.client;
    try {
      final List<Map<String, dynamic>> data = await supabase
          .from('pelanggan')
          .select()
          .order('id_pelanggan', ascending: true);

      print("Data pelanggan dari Supabase: $data"); // Debugging

      setState(() {
        _pelangganList = data;
        _filteredPelangganList = data;
      });
    } catch (error) {
      print('Error fetching data: $error');
    }
  }

  void _filterPelanggan() {
    String query = _searchController.text.toLowerCase();

    setState(() {
      _filteredPelangganList = _pelangganList
          .where((pelanggan) =>
              pelanggan['nama_pelanggan'].toLowerCase().contains(query) ||
              pelanggan['alamat'].toLowerCase().contains(query) ||
              pelanggan['no_tlp'].contains(query))
          .toList();
    });
  }

  Future<void> _addPelanggan() async {
    final supabase = Supabase.instance.client;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final namaPelanggan = _namaPelangganController.text.trim();
    final alamat = _alamatController.text.trim();
    final noTlp = _noTlpController.text.trim();

    try {
      // Cek apakah data pelanggan sudah ada
      final List<Map<String, dynamic>> existingPelanggan = await supabase
          .from('pelanggan')
          .select()
          .or('nama_pelanggan.eq.$namaPelanggan,no_tlp.eq.$noTlp');

      if (existingPelanggan.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data pelanggan sudah ada!'),
            backgroundColor: Colors.red,
          ),
        );
        return; // Hentikan proses insert jika data sudah ada
      }

      // Jika pelanggan belum ada, tambahkan pelanggan baru
      await supabase.from('pelanggan').insert({
        'nama_pelanggan': namaPelanggan,
        'alamat': alamat,
        'no_tlp': noTlp,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pelanggan berhasil ditambahkan!'),
          backgroundColor: Colors.green,
        ),
      );

      _fetchPelangganData();
      _clearFields();
      Navigator.pop(context);
    } catch (error) {
      print('Error adding pelanggan: $error');
    }
  }

  Future<void> _editPelanggan(int id) async {
    final supabase = Supabase.instance.client;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final namaPelanggan = _namaPelangganController.text.trim();
    final alamat = _alamatController.text.trim();
    final noTlp = _noTlpController.text.trim();

    try {
      await supabase.from('pelanggan').update({
        'nama_pelanggan': namaPelanggan,
        'alamat': alamat,
        'no_tlp': noTlp,
      }).eq('id_pelanggan', id);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pelanggan berhasil diperbarui!'),
          backgroundColor: Colors.blue,
        ),
      );

      _fetchPelangganData();
      _clearFields();
      Navigator.pop(context);
    } catch (error) {
      print('Error updating pelanggan: $error');
    }
  }

  Future<void> _deletePelanggan(int id) async {
    final supabase = Supabase.instance.client;

    try {
      await supabase.from('pelanggan').delete().eq('id_pelanggan', id);

      _fetchPelangganData();
    } catch (error) {
      print('Error deleting pelanggan: $error');
    }
  }

  void _clearFields() {
    _namaPelangganController.clear();
    _alamatController.clear();
    _noTlpController.clear();
  }

  void _showPelangganDialog({int? id}) {
    final pelanggan =
        id != null && _pelangganList.any((p) => p['id_pelanggan'] == id)
            ? _pelangganList.firstWhere((p) => p['id_pelanggan'] == id)
            : null;

    _namaPelangganController.text = pelanggan?['nama_pelanggan'] ?? '';
    _alamatController.text = pelanggan?['alamat'] ?? '';
    _noTlpController.text = pelanggan?['no_tlp'] ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(id == null ? "Tambah Pelanggan" : "Edit Pelanggan"),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _namaPelangganController,
                  decoration:
                      const InputDecoration(labelText: "Nama Pelanggan"),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama Pelanggan tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _alamatController,
                  decoration: const InputDecoration(labelText: "Alamat"),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Alamat tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _noTlpController,
                  decoration: const InputDecoration(
                    labelText: "No. Telp",
                    counterText: "", // Menghilangkan counter bawaan
                  ),
                  keyboardType: TextInputType.phone,
                  maxLength: 13, // Batas maksimal 13 angka
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly
                  ], // Hanya angka
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'No. Telp tidak boleh kosong';
                    }
                    if (value.length > 13) {
                      return 'No. Telp maksimal 13 angka';
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
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: id == null ? _addPelanggan : () => _editPelanggan(id),
              child: const Text("Simpan"),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeletePelanggan(int id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Konfirmasi Hapus"),
          content:
              const Text("Apakah Anda yakin ingin menghapus pelanggan ini?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Tutup dialog
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Tutup dialog
                _deletePelanggan(id); // Hapus pelanggan
              },
              // style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Hapus", style: TextStyle(color: Colors.red)),
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
              decoration: InputDecoration(
                hintText: "Cari pelanggan...",
                hintStyle:
                    GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _filteredPelangganList.isEmpty
                  ? Center(
                      child: Text(
                        'Belum ada Pelanggan',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredPelangganList.length,
                      itemBuilder: (context, index) {
                        final pelanggan = _filteredPelangganList[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            title: Text(
                              pelanggan['nama_pelanggan'],
                              style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF091057)),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Alamat: ${pelanggan['alamat']}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: const Color(0xFF024CAA),
                                  ),
                                ),
                                Text(
                                  'No. Telp: ${pelanggan['no_tlp']}',
                                  style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: const Color(0xFFEC8305)),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Color(0xFF091057)),
                                  onPressed: () => _showPelangganDialog(
                                      id: pelanggan['id_pelanggan']),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _confirmDeletePelanggan(
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPelangganDialog(),
        backgroundColor: const Color(0xFF091057),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
