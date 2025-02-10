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
    //menambahkan produk ke keranjang
    // Cek apakah produk sudah ada dalam keranjang
    final existingItemIndex = keranjang.indexWhere(
      (item) => item['id_produk'] == produk['id_produk'],
    );

    if (existingItemIndex != -1) {
      // Jika produk sudah ada, cukup tambahkan jumlahnya
      final existingItem = keranjang[existingItemIndex];
      final availableStock = produk['stok'] -
          existingItem['jumlah']; // Stok sisa setelah menambah jumlah
      if (availableStock >= jumlah) {
        setState(() {
          existingItem['jumlah'] += jumlah;
          existingItem['subtotal'] = existingItem['jumlah'] * produk['harga'];
          totalHarga += produk['harga'] * jumlah;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Stok tidak mencukupi untuk menambah jumlah!'),
        ));
      }
    } else {
      // Jika produk belum ada di keranjang, tambahkan produk baru
      if (produk['stok'] >= jumlah) {
        final subtotal = produk['harga'] * jumlah;
        setState(() {
          keranjang.add({
            'id_produk': produk['id_produk'],
            'nama_produk': produk['nama_produk'],
            'jumlah': jumlah,
            'subtotal': subtotal,
          });
          totalHarga += subtotal;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Stok tidak mencukupi!'),
        ));
      }
    }

    // Update stok produk setelah ditambahkan ke keranjang
    final updatedStock = produk['stok'] - jumlah;
    setState(() {
      produk['stok'] = updatedStock;
    });
  }

  void _removeFromCart(int index) {
    final item = keranjang[index];
    final produk = produkList.firstWhere(
      (p) => p['id_produk'] == item['id_produk'],
      orElse: () => {},
    );

    setState(() {
      if (item['jumlah'] > 1) {
        item['jumlah'] -= 1;
        item['subtotal'] = item['jumlah'] * produk['harga'];
        totalHarga -= produk['harga'];

        // Pastikan stok tidak menjadi negatif
        produk['stok'] = (produk['stok'] + 1).clamp(0, double.infinity);
      } else {
        totalHarga -= item['subtotal'];
        keranjang.removeAt(index);

        // Kembalikan stok produk yang dihapus dari keranjang
        produk['stok'] =
            (produk['stok'] + item['jumlah']).clamp(0, double.infinity);
      }
    });
  }

  Future<void> _simpanTransaksi() async {
    // Pastikan keranjang tidak kosong
    if (keranjang.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Keranjang tidak boleh kosong!'),
      ));
      return;
    }

    // Pastikan pelanggan dipilih, jika tidak, gunakan pelanggan default
    Map<String, dynamic> pelanggan = selectedPelanggan ??
        {
          'id_pelanggan': 0,
          'nama_pelanggan': 'User',
          'alamat': '-',
          'no_tlp': '-',
        };

    try {
      // Simpan transaksi ke tabel 'penjualan'
      final response = await supabase.from('penjualan').insert([
        {
          'tgl_penjualan': DateTime.now().toIso8601String(),
          'total_harga': totalHarga,
          'id_pelanggan':
              pelanggan['id_pelanggan'] == 0 ? null : pelanggan['id_pelanggan'],
        }
      ]).select();

      if (response.isNotEmpty) {
        final penjualanId = response[0]['id_penjualan']; // Ambil ID transaksi

        // Simpan detail transaksi ke 'detail_penjualan'
        for (final item in keranjang) {
          await supabase.from('detail_penjualan').insert({
            'id_penjualan': penjualanId,
            'id_produk': item['id_produk'],
            'jumlah_produk': item['jumlah'],
            'subtotal': item['subtotal'],
            'created_at': DateTime.now().toIso8601String(),
          });

          // Perbarui stok produk di tabel 'produk'
          final produk = produkList.firstWhere(
            (p) => p['id_produk'] == item['id_produk'],
            orElse: () => {},
          );

          if (produk.isNotEmpty) {
            final stokBaru = produk['stok'] - item['jumlah'];
            if (stokBaru >= 0) {
              await supabase.from('produk').update({'stok': stokBaru}).eq(
                'id_produk',
                item['id_produk'],
              );
            }
          }
        }

        // Beri notifikasi transaksi berhasil
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaksi berhasil disimpan!'),
            duration: Duration(seconds: 1),
          ),
        );

        // Reset keranjang setelah transaksi sukses
        setState(() {
          keranjang.clear();
          totalHarga = 0.0;
          selectedPelanggan = null;
        });

        // Navigasi ke halaman Riwayat
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Riwayat()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Gagal menyimpan transaksi.'),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Terjadi kesalahan: $e'),
      ));
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
                itemCount:
                    keranjang.length, // Jumlah item yang ada di keranjang
                itemBuilder: (context, index) {
                  final item = keranjang[index]; // Ambil item berdasarkan index
                  final produkId = item['id_produk']; // ID produk
                  final produk = produkList.firstWhere(
                    (p) => p['id_produk'] == produkId,
                    orElse: () =>
                        {'harga': 0}, // Jika tidak ditemukan, gunakan harga 0
                  );
                  final harga =
                      produk['harga'] ?? 0; // Menggunakan harga produk
                  final jumlah = item['jumlah'] ??
                      0; // Menggunakan jumlah default 0 jika null
                  final subtotal =
                      harga * jumlah; // Menghitung subtotal setiap item

                  // Update subtotal untuk setiap item
                  item['subtotal'] = subtotal;

                  return ListTile(
                    title: Text(item['nama_produk']), // Nama produk
                    subtitle: Text(
                      'Jumlah: $jumlah | Subtotal: Rp${subtotal.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Tombol untuk mengurangi jumlah produk
                        IconButton(
                          icon: const Icon(Icons.remove, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              if (item['jumlah'] > 1) {
                                item['jumlah']--;
                                item['subtotal'] =
                                    item['jumlah'] * harga; // Update subtotal
                                totalHarga -= harga; // Update totalHarga
                              } else {
                                totalHarga -=
                                    item['subtotal']; // Kurangi total harga
                                keranjang.removeAt(
                                    index); // Hapus item jika jumlah = 0
                              }
                            });
                          },
                        ),
                        // Menampilkan jumlah produk
                        Text(item['jumlah'].toString()),
                        // Tombol untuk menambah jumlah produk
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.green),
                          onPressed: () {
                            final stokProduk =
                                produk['stok'] ?? 0; // Cek stok produk
                            if (item['jumlah'] < stokProduk) {
                              setState(() {
                                item['jumlah']++;
                                item['subtotal'] =
                                    item['jumlah'] * harga; // Update subtotal
                                totalHarga += harga; // Update totalHarga
                              });
                            } else {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                content: Text('Stok tidak mencukupi!'),
                              ));
                            }
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
