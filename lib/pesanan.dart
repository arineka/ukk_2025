import 'package:coba/history.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Pesanan extends StatefulWidget {
  const Pesanan({Key? key}) : super(key: key);

  @override
  State<Pesanan> createState() => _PesananState();
}

class _PesananState extends State<Pesanan> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> penjualanList = [];
  List<Map<String, dynamic>> produkList = [];
  List<Map<String, dynamic>> pelangganList = [];
  Map<String, dynamic>? selectedPelanggan;
  List<Map<String, dynamic>> keranjang = [];
  double totalHarga = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final produkResponse = await supabase.from('produk').select();
      final pelangganResponse = await supabase.from('pelanggan').select();
      final penjualanResponse = await supabase.from('penjualan').select();

      setState(() {
        produkList = produkResponse as List<Map<String, dynamic>>;
        pelangganList = pelangganResponse as List<Map<String, dynamic>>;
        penjualanList = penjualanResponse as List<Map<String, dynamic>>;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil data: $e')),
      );
    }
  }

  void _addToCart(Map<String, dynamic> produk, int jumlah) {
    final existingItemIndex = keranjang
        .indexWhere((item) => item['produk_id'] == produk['produk_id']);

    // Hitung stok tersisa berdasarkan jumlah produk di keranjang
    final stokTersisa = produk['stok'] -
        keranjang
            .where((item) => item['produk_id'] == produk['produk_id'])
            .fold<int>(
                0, (prev, item) => prev + (item['jumlah'] as int)); // Fix here

    if (stokTersisa < jumlah) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stok tidak mencukupi! Tersisa $stokTersisa')),
      );
      return;
    }

    setState(() {
      if (existingItemIndex != -1) {
        // Jika produk sudah ada di keranjang, tambahkan jumlahnya
        keranjang[existingItemIndex]['jumlah'] += jumlah;
        keranjang[existingItemIndex]['subtotal'] =
            keranjang[existingItemIndex]['jumlah'] * produk['harga'];
      } else {
        // Jika produk belum ada di keranjang, tambahkan sebagai item baru
        keranjang.add({
          'produk_id': produk['produk_id'],
          'nama_produk': produk['nama_produk'],
          'harga': produk['harga'],
          'jumlah': jumlah,
          'subtotal': produk['harga'] * jumlah,
        });
      }

      // Update total harga
      totalHarga += produk['harga'] * jumlah;
    });
  }

  void _removeFromCart(int index) {
    final item = keranjang[index];

    setState(() {
      if (item['jumlah'] > 1) {
        item['jumlah'] -= 1;
        item['subtotal'] = item['jumlah'] * item['harga'];
        totalHarga -= item['harga'];
      } else {
        totalHarga -= item['subtotal'];
        keranjang.removeAt(index);
      }
    });
  }

  Future<void> _simpanTransaksi() async {
    if (keranjang.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keranjang tidak boleh kosong!')),
      );
      return;
    }

    final pelanggan = selectedPelanggan ??
        {
          'id_pelanggan': 0,
          'nama_pelanggan': 'Anonim',
        };

    try {
      final response = await supabase.from('penjualan').insert({
        'tgl_penjualan': DateTime.now().toIso8601String(),
        'total_harga': totalHarga,
        'id_pelanggan': pelanggan['id_pelanggan'],
      }).select();

      if (response.isNotEmpty) {
        final penjualanId = response[0]['id_penjualan'];

        for (final item in keranjang) {
          await supabase.from('detail_penjualan').insert({
            'penjualan_id': penjualanId,
            'produk_id': item['produk_id'],
            'jumlah_produk': item['jumlah'],
            'subtotal': item['subtotal'],
          });

          // Perbarui stok produk di database
          await supabase.from('produk').update({
            'stok': Supabase.instance.client.rpc(
              'kurangi_stok',
              params: {
                'produk_id': item['produk_id'],
                'jumlah': item['jumlah']
              },
            )
          }).eq('produk_id', item['produk_id']);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi berhasil disimpan!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Riwayat()),
        );

        setState(() {
          keranjang.clear();
          totalHarga = 0.0;
          selectedPelanggan = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan transaksi.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<int>(
              decoration: InputDecoration(
                labelText: 'Pilih Pelanggan',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: pelangganList.map((pelanggan) {
                return DropdownMenuItem<int>(
                  value: pelanggan['id_pelanggan'],
                  child: Text(pelanggan['nama_pelanggan']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedPelanggan = pelangganList
                      .firstWhere((pel) => pel['id_pelanggan'] == value);
                });
              },
              value: selectedPelanggan?['id_pelanggan'],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Map<String, dynamic>>(
              decoration: InputDecoration(
                labelText: 'Pilih Produk',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: produkList.map((produk) {
                return DropdownMenuItem(
                  value: produk,
                  child: Text(
                      '${produk['nama_produk']} (Stok: ${produk['stok']})'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) _addToCart(value, 1);
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: keranjang.length,
                itemBuilder: (context, index) {
                  final item = keranjang[index];
                  return ListTile(
                    title: Text(item['nama_produk']),
                    subtitle: Text(
                        'Jumlah: ${item['jumlah']} | Subtotal: Rp${item['subtotal']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle,
                              color: Colors.red),
                          onPressed: () => _removeFromCart(index),
                        ),
                        Text(item['jumlah'].toString()),
                        IconButton(
                          icon:
                              const Icon(Icons.add_circle, color: Colors.green),
                          onPressed: () {
                            final produk = produkList.firstWhere(
                                (p) => p['produk_id'] == item['produk_id']);
                            _addToCart(produk, 1);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total: Rp${totalHarga.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                ElevatedButton(
                  onPressed: _simpanTransaksi,
                  child: const Text('Simpan'),
                ),
              ],
            ),
          ],
        ),
      ),
      // bottomNavigationBar: BottomNavBar(),
    );
  }
}