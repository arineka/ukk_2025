import 'package:coba/history.dart';
import 'package:coba/main.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

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
    // Cari produk di dalam keranjang
    final existingItemIndex = keranjang.indexWhere(
      (item) => item['id_produk'] == produk['id_produk'],
    );

    if (existingItemIndex != -1) {
      // Jika produk sudah ada dalam keranjang, tambahkan jumlahnya
      final existingItem = keranjang[existingItemIndex];
      final totalJumlahSetelahTambah = existingItem['jumlah'] + jumlah;

      if (totalJumlahSetelahTambah <= produk['stok']) {
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
      // Jika produk belum ada di keranjang
      if (jumlah <= produk['stok']) {
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
  }

  // Update stok produk setelah ditambahkan ke keranjang
  // final updatedStock = produk['stok'] - jumlah;
  // setState(() {
  //   produk['stok'] = updatedStock;
  // });

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
    if (keranjang.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keranjang tidak boleh kosong!')),
      );
      return;
    }

    Map<String, dynamic> pelanggan = selectedPelanggan ??
        {
          'id_pelanggan': 0,
          'nama_pelanggan': 'User',
          'alamat': '-',
          'no_tlp': '-',
        };

    try {
      final response = await supabase.from('penjualan').insert([
        {
          'tgl_penjualan': DateTime.now().toIso8601String(),
          'total_harga': totalHarga,
          'id_pelanggan':
              pelanggan['id_pelanggan'] == 0 ? null : pelanggan['id_pelanggan'],
        }
      ]).select();

      if (response.isNotEmpty) {
        final penjualanId = response[0]['id_penjualan'];

        for (final item in keranjang) {
          await supabase.from('detail_penjualan').insert({
            'id_penjualan': penjualanId,
            'id_produk': item['id_produk'],
            'jumlah_produk': item['jumlah'],
            'subtotal': item['subtotal'],
            'created_at': DateTime.now().toIso8601String(),
          });

          await supabase.from('produk').update({
            'stok': produkList.firstWhere(
                  (p) => p['id_produk'] == item['id_produk'],
                )['stok'] -
                item['jumlah']
          }).eq('id_produk', item['id_produk']);
        }

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Transaksi berhasil disimpan!'),
        ));

        _showReceiptDialog(context, penjualanId, keranjang, totalHarga,
            pelanggan['nama_pelanggan']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Terjadi kesalahan: $e'),
      ));
    }
  }

  void _showReceiptDialog(
      BuildContext context,
      int penjualanId,
      List<Map<String, dynamic>> keranjang,
      double totalHarga,
      String pelanggan) {
    final currencyFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Center(
            child: Text(
              "Struk Pembelian",
              style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Pelanggan: $pelanggan",
                  style:
                      GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                ),
                const Divider(thickness: 1, height: 20),
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: keranjang.length,
                  itemBuilder: (context, index) {
                    final item = keranjang[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "${item['nama_produk']} x${item['jumlah']}",
                              style: GoogleFonts.poppins(
                                  fontSize: 14, color: Colors.black87),
                            ),
                          ),
                          Text(
                            currencyFormat.format(item['subtotal']),
                            style: GoogleFonts.poppins(
                                fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(thickness: 1, height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total",
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    Text(
                      currencyFormat.format(totalHarga),
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                _generatePDF(penjualanId, pelanggan, keranjang, totalHarga);
              },
              icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
              label:
                  Text("Simpan PDF", style: GoogleFonts.poppins(fontSize: 14)),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MainScreen(selectedIndex: 2)),
                );
              },
              icon: const Icon(Icons.history, color: Colors.blue),
              label: Text("Lihat Riwayat",
                  style: GoogleFonts.poppins(fontSize: 14)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _generatePDF(int penjualanId, String pelanggan,
      List<Map<String, dynamic>> keranjang, double totalHarga) async {
    final pdf = pw.Document();
    final currencyFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text("Struk Pembelian",
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 10),
              pw.Text("ID Penjualan: $penjualanId",
                  style: pw.TextStyle(fontSize: 14)),
              pw.Text("Pelanggan: $pelanggan",
                  style: pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.Column(
                children: keranjang.map((item) {
                  return pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("${item['nama_produk']} x${item['jumlah']}",
                          style: pw.TextStyle(fontSize: 14)),
                      pw.Text(currencyFormat.format(item['subtotal']),
                          style: pw.TextStyle(fontSize: 14)),
                    ],
                  );
                }).toList(),
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Total",
                      style: pw.TextStyle(
                          fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.Text(currencyFormat.format(totalHarga),
                      style: pw.TextStyle(
                          fontSize: 16, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
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
                labelStyle: GoogleFonts.poppins(fontSize: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              items: pelangganList.map((pelanggan) {
                return DropdownMenuItem<int>(
                  value: pelanggan['id_pelanggan'],
                  child: Text(
                    pelanggan['nama_pelanggan'],
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
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
                labelStyle: GoogleFonts.poppins(fontSize: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              items: produkList.map((produk) {
                return DropdownMenuItem(
                  value: produk,
                  child: Text(
                    '${produk['nama_produk']} (Stok: ${produk['stok']})',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
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
                  final produkId = item['id_produk'];
                  final produk = produkList.firstWhere(
                    (p) => p['id_produk'] == produkId,
                    orElse: () => {'harga': 0},
                  );
                  final harga = produk['harga'] ?? 0;
                  final jumlah = item['jumlah'] ?? 0;
                  final subtotal = harga * jumlah;

                  item['subtotal'] = subtotal;

                  return ListTile(
                    title: Text(
                      item['nama_produk'],
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF091057)),
                    ),
                    subtitle: Text(
                      'Jumlah: $jumlah | Subtotal: Rp${subtotal.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                          fontSize: 14, color: Colors.grey[700]),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              if (item['jumlah'] > 1) {
                                item['jumlah']--;
                                item['subtotal'] = item['jumlah'] * harga;
                                totalHarga -= harga;
                              } else {
                                totalHarga -= item['subtotal'];
                                keranjang.removeAt(index);
                              }
                            });
                          },
                        ),
                        Text(
                          item['jumlah'].toString(),
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.green),
                          onPressed: () {
                            final stokProduk = produk['stok'];
                            if (item['jumlah'] + 1 <= stokProduk) {
                              setState(() {
                                item['jumlah']++;
                                item['subtotal'] = item['jumlah'] * harga;
                                totalHarga += harga;
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Stok tidak mencukupi!',
                                    style: GoogleFonts.poppins(),
                                  ),
                                ),
                              );
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
                Text(
                  'Total: Rp${totalHarga.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFEC8305),
                  ),
                ),
                ElevatedButton(
                  onPressed: _simpanTransaksi,
                  child: Text(
                    'Simpan',
                    style: GoogleFonts.poppins(
                        fontSize: 16, color: const Color(0xFF091057)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
