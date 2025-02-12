import 'package:coba/main.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:html' as html;
import 'dart:typed_data';

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
      // Mengambil data dari tabel 'produk'
      final produkResponse = await supabase.from('produk').select();

      // Mengambil data dari tabel 'pelanggan'
      final pelangganResponse = await supabase.from('pelanggan').select();

      // Mengambil data dari tabel 'penjualan'
      final penjualanResponse = await supabase.from('penjualan').select();

      setState(() {
        produkList =
            produkResponse as List<Map<String, dynamic>>; // Simpan data produk
        pelangganList = pelangganResponse
            as List<Map<String, dynamic>>; // Simpan data pelanggan
        penjualanList = penjualanResponse
            as List<Map<String, dynamic>>; // Simpan data penjualan
      });
    } catch (e) {
      // Jika terjadi error saat mengambil data, tampilkan pesan error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil data: $e')),
      );
    }
  }

  void _addToCart(Map<String, dynamic> produk, int jumlah) {
    // Cari apakah produk sudah ada dalam keranjang berdasarkan id_produk
    final existingItemIndex = keranjang.indexWhere(
      (item) => item['id_produk'] == produk['id_produk'],
    );

    if (existingItemIndex != -1) {
      // Jika produk sudah ada di keranjang, tambahkan jumlahnya
      final existingItem = keranjang[existingItemIndex];
      final totalJumlahSetelahTambah = existingItem['jumlah'] + jumlah;

      if (totalJumlahSetelahTambah <= produk['stok']) {
        // Jika jumlah total tidak melebihi stok, perbarui jumlah dan subtotal
        setState(() {
          existingItem['jumlah'] += jumlah;
          existingItem['subtotal'] = existingItem['jumlah'] * produk['harga'];
          totalHarga += produk['harga'] * jumlah;
        });
      } else {
        // Jika stok tidak mencukupi, tampilkan notifikasi ke pengguna
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Stok tidak mencukupi untuk menambah jumlah!'),
        ));
      }
    } else {
      // Jika produk belum ada dalam keranjang
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
        // Jika stok tidak mencukupi, tampilkan notifikasi ke pengguna
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
    // Ambil item produk dari keranjang berdasarkan indeks
    final item = keranjang[index];

    // Cari produk di daftar produk berdasarkan id_produk
    final produk = produkList.firstWhere(
      (p) => p['id_produk'] == item['id_produk'],
      orElse: () => {}, // Jika produk tidak ditemukan, return objek kosong
    );

    setState(() {
      if (item['jumlah'] > 1) {
        // Jika jumlah produk dalam keranjang lebih dari 1, kurangi jumlahnya
        item['jumlah'] -= 1;
        item['subtotal'] = item['jumlah'] * produk['harga'];
        totalHarga -=
            produk['harga']; // Kurangi total harga sesuai harga produk

        // Pastikan stok produk tidak negatif saat dikembalikan
        produk['stok'] = (produk['stok'] + 1).clamp(0, double.infinity);
      } else {
        // Jika jumlah produk dalam keranjang hanya 1, hapus produk dari keranjang
        totalHarga -=
            item['subtotal']; // Kurangi total harga dengan subtotal produk
        keranjang.removeAt(index); // Hapus produk dari keranjang

        // Kembalikan stok produk yang dihapus dari keranjang
        produk['stok'] =
            (produk['stok'] + item['jumlah']).clamp(0, double.infinity);
      }
    });
  }

  Future<void> _simpanTransaksi() async {
    // Cek apakah keranjang kosong sebelum menyimpan transaksi
    if (keranjang.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keranjang tidak boleh kosong!')),
      );
      return; // Hentikan proses jika keranjang kosong
    }

    // Jika tidak ada pelanggan yang dipilih, buat pelanggan default
    Map<String, dynamic> pelanggan = selectedPelanggan ??
        {
          'id_pelanggan': 0,
          'nama_pelanggan': 'User',
          'alamat': '-',
          'no_tlp': '-',
        };

    try {
      // Simpan data transaksi ke tabel 'penjualan' di Supabase
      final response = await supabase.from('penjualan').insert([
        {
          'tgl_penjualan': DateTime.now().toIso8601String(), // Waktu transaksi
          'total_harga': totalHarga, // Total harga dari keranjang
          'id_pelanggan': pelanggan['id_pelanggan'] == 0
              ? null
              : pelanggan['id_pelanggan'], // Jika pelanggan default, set null
        }
      ]).select(); // Ambil data transaksi yang baru saja disimpan

      if (response.isNotEmpty) {
        final penjualanId =
            response[0]['id_penjualan']; // Ambil ID transaksi yang baru dibuat

        // Simpan detail transaksi untuk setiap produk di keranjang
        for (final item in keranjang) {
          await supabase.from('detail_penjualan').insert({
            'id_penjualan': penjualanId, // ID transaksi
            'id_produk': item['id_produk'], // ID produk yang dibeli
            'jumlah_produk': item['jumlah'], // Jumlah produk yang dibeli
            'subtotal': item['subtotal'], // Harga total per produk
            'created_at':
                DateTime.now().toIso8601String(), // Timestamp transaksi
          });

          // Update stok produk di database dengan mengurangi jumlah yang terjual
          await supabase.from('produk').update({
            'stok': produkList.firstWhere(
                  (p) => p['id_produk'] == item['id_produk'],
                )['stok'] -
                item[
                    'jumlah'], // Kurangi stok dengan jumlah produk yang terjual
          }).eq('id_produk', item['id_produk']);
        }

        // Tampilkan notifikasi bahwa transaksi berhasil disimpan
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Transaksi berhasil disimpan!'),
        ));

        // Tampilkan struk atau detail transaksi setelah transaksi selesai
        _showReceiptDialog(
          context,
          penjualanId,
          keranjang,
          totalHarga,
          pelanggan['nama_pelanggan'],
        );
      }
    } catch (e) {
      // Tangani kesalahan jika terjadi error saat menyimpan transaksi
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
    // Format mata uang Indonesia (IDR) menggunakan package intl
    final currencyFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    // Menampilkan dialog struk pembelian
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                  15)), // Membuat sudut dialog lebih membulat
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
            width: double
                .maxFinite, // Agar konten dialog dapat menyesuaikan ukuran
            child: Column(
              mainAxisSize:
                  MainAxisSize.min, // Menyesuaikan tinggi sesuai konten
              children: [
                // Menampilkan nama pelanggan
                Text(
                  "Pelanggan: $pelanggan",
                  style:
                      GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                ),
                const Divider(thickness: 1, height: 20), // Garis pemisah

                // Menampilkan daftar produk yang dibeli
                ListView.builder(
                  shrinkWrap: true, // Agar tidak memakan seluruh layar
                  itemCount: keranjang.length, // Jumlah item dalam keranjang
                  itemBuilder: (context, index) {
                    final item =
                        keranjang[index]; // Ambil item berdasarkan index
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment
                            .spaceBetween, // Item sejajar ke kiri & kanan
                        children: [
                          Expanded(
                            child: Text(
                              "${item['nama_produk']} x${item['jumlah']}",
                              style: GoogleFonts.poppins(
                                  fontSize: 14, color: Colors.black87),
                            ),
                          ),
                          // Menampilkan subtotal harga untuk produk tertentu
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

                const Divider(thickness: 1, height: 20), // Garis pemisah

                // Menampilkan total harga pembelian
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

          // Tombol aksi dalam dialog
          actions: [
            Row(
              children: [
                // Tombol untuk menyimpan struk dalam format PDF
                TextButton.icon(
                  onPressed: () {
                    _generatePDF(penjualanId, pelanggan, keranjang, totalHarga);
                  },
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  label: Text("Simpan PDF",
                      style: GoogleFonts.poppins(fontSize: 14)),
                ),

                // Tombol untuk melihat riwayat transaksi
                TextButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MainScreen(
                              selectedIndex:
                                  2)), // Arahkan ke halaman riwayat transaksi
                    );
                  },
                  icon: const Icon(Icons.history, color: Color(0xFF091057)),
                  label: Text("Lihat Riwayat",
                      style: GoogleFonts.poppins(fontSize: 14)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _generatePDF(int penjualanId, String pelanggan,
      List<Map<String, dynamic>> keranjang, double totalHarga) async {
    // Membuat dokumen PDF baru menggunakan package `pdf`
    final pdf = pw.Document();

    // Format mata uang Indonesia (IDR) menggunakan package `intl`
    final currencyFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    // Menambahkan halaman ke dalam PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4, // Format halaman A4
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start, // Konten rata kiri
            children: [
              // Menampilkan judul struk pembelian di tengah
              pw.Center(
                child: pw.Text("Struk Pembelian",
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 10), // Jarak antar elemen

              // Informasi transaksi
              pw.Text("No. Penjualan: $penjualanId",
                  style: const pw.TextStyle(fontSize: 14)),
              pw.Text("Pelanggan: $pelanggan",
                  style: const pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 10),
              pw.Divider(), // Garis pemisah

              // Menampilkan daftar produk yang dibeli
              pw.Column(
                children: keranjang.map((item) {
                  return pw.Row(
                    mainAxisAlignment: pw
                        .MainAxisAlignment.spaceBetween, // Sejajar kiri & kanan
                    children: [
                      pw.Text("${item['nama_produk']} x${item['jumlah']}",
                          style: const pw.TextStyle(fontSize: 14)),
                      pw.Text(currencyFormat.format(item['subtotal']),
                          style: const pw.TextStyle(fontSize: 14)),
                    ],
                  );
                }).toList(),
              ),
              pw.Divider(), // Garis pemisah

              // Menampilkan total harga transaksi
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

    try {
      // Menyimpan PDF dalam bentuk byte array
      final Uint8List pdfBytes = await pdf.save();

      // Membuat objek Blob dari data PDF untuk didownload di browser
      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);

      // Membuat elemen <a> (anchor) untuk mengunduh file PDF
      final anchor = html.AnchorElement(href: url)
        ..setAttribute(
            "download", "Struk_$penjualanId.pdf") // Nama file saat diunduh
        ..click(); // Klik otomatis untuk mengunduh file

      // Membersihkan URL setelah download selesai
      html.Url.revokeObjectUrl(url);

      // Menampilkan notifikasi sukses di layar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Struk berhasil diunduh!')),
      );
    } catch (e) {
      // Menampilkan notifikasi jika terjadi error saat menyimpan PDF
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan struk: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding:
            const EdgeInsets.all(16.0), // Memberikan padding ke seluruh body
        child: Column(
          children: [
            // Dropdown untuk memilih pelanggan
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
                // Mengupdate pelanggan yang dipilih
                setState(() {
                  selectedPelanggan = pelangganList
                      .firstWhere((pel) => pel['id_pelanggan'] == value);
                });
              },
              value: selectedPelanggan?[
                  'id_pelanggan'], // Menampilkan pelanggan yang sudah dipilih
            ),
            const SizedBox(height: 16),

            // Dropdown untuk memilih produk
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
                    '${produk['nama_produk']} (Stok: ${produk['stok']})', // Menampilkan nama produk dan stok yang tersedia
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                // Menambahkan produk ke keranjang dengan jumlah awal 1
                if (value != null) _addToCart(value, 1);
              },
            ),
            const SizedBox(height: 16),

            // Menampilkan daftar produk dalam keranjang
            Expanded(
              child: ListView.builder(
                itemCount: keranjang.length, // Jumlah item dalam keranjang
                itemBuilder: (context, index) {
                  final item =
                      keranjang[index]; // Produk saat ini dalam iterasi
                  final produkId = item['id_produk'];

                  // Mencari produk berdasarkan ID
                  final produk = produkList.firstWhere(
                    (p) => p['id_produk'] == produkId,
                    orElse: () =>
                        {'harga': 0}, // Jika tidak ditemukan, harga default 0
                  );

                  final harga = produk['harga'] ?? 0;
                  final jumlah = item['jumlah'] ?? 0;
                  final subtotal = harga * jumlah;

                  item['subtotal'] = subtotal; // Mengupdate subtotal

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
                        // Tombol untuk mengurangi jumlah produk
                        IconButton(
                          icon: const Icon(Icons.remove, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              if (item['jumlah'] > 1) {
                                item['jumlah']--;
                                item['subtotal'] = item['jumlah'] * harga;
                                totalHarga -= harga; // Mengurangi total harga
                              } else {
                                totalHarga -= item[
                                    'subtotal']; // Mengurangi total harga dengan subtotal produk yang dihapus
                                keranjang.removeAt(
                                    index); // Menghapus produk dari keranjang jika jumlahnya 1
                              }
                            });
                          },
                        ),

                        // Menampilkan jumlah produk dalam keranjang
                        Text(
                          item['jumlah'].toString(),
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),

                        // Tombol untuk menambah jumlah produk
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.green),
                          onPressed: () {
                            final stokProduk = produk['stok'];
                            if (item['jumlah'] + 1 <= stokProduk) {
                              setState(() {
                                item['jumlah']++;
                                item['subtotal'] = item['jumlah'] * harga;
                                totalHarga +=
                                    harga; // Menambahkan harga ke total
                              });
                            } else {
                              // Menampilkan pesan error jika stok tidak mencukupi
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

            // Menampilkan total harga dan tombol simpan transaksi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Menampilkan total harga
                Text(
                  'Total: Rp${totalHarga.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFEC8305),
                  ),
                ),

                // Tombol untuk menyimpan transaksi
                ElevatedButton(
                  onPressed:
                      _simpanTransaksi, // Fungsi untuk menyimpan transaksi
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
