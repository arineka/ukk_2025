import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Riwayat extends StatefulWidget {
  const Riwayat({super.key});

  @override
  State<Riwayat> createState() => _RiwayatState();
}

class _RiwayatState extends State<Riwayat> {
  List<Map<String, dynamic>> transaksiList = [];

  @override
  void initState() {
    super.initState();
    fetchRiwayat();
  }

  Future<void> fetchRiwayat() async {
    try {
      // Mengambil instance Supabase client
      final supabase = Supabase.instance.client;

      // Mengambil data dari tabel 'penjualan' dengan informasi pelanggan terkait
      // Data diurutkan berdasarkan tanggal penjualan dan id_penjualan secara descending (terbaru di atas)
      final penjualanResponse = await supabase
          .from('penjualan')
          .select('*, pelanggan(nama_pelanggan)')
          .order('tgl_penjualan', ascending: false)
          .order('id_penjualan', ascending: false);

      // Jika ada data penjualan yang ditemukan
      if (penjualanResponse.isNotEmpty) {
        // Mengambil detail penjualan untuk setiap transaksi dalam daftar penjualan
        final futures = penjualanResponse.map((penjualan) async {
          // Mengambil detail penjualan dari tabel 'detail_penjualan' dengan informasi produk terkait
          final detailResponse = await supabase
              .from('detail_penjualan')
              .select('*, produk(nama_produk)')
              .eq(
                  'id_penjualan',
                  penjualan[
                      'id_penjualan']) // Hanya mengambil detail untuk transaksi tertentu
              .order('id_detail',
                  ascending:
                      false); // Mengurutkan berdasarkan id_detail secara descending

          // Mengembalikan data dalam bentuk map yang berisi informasi penjualan dan detailnya
          return {
            'penjualan': penjualan,
            'details': detailResponse,
          };
        }).toList();

        // Menjalankan semua request ke database secara bersamaan dan menunggu hasilnya
        final results = await Future.wait(futures);

        // Memperbarui state dengan daftar transaksi yang telah diambil
        setState(() {
          transaksiList = results;
        });
      }
    } catch (e) {
      // Menampilkan pesan error jika terjadi kesalahan saat mengambil data
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Terjadi kesalahan: $e'),
      ));
    }
  }

  Future<void> refreshRiwayat() async {
    await fetchRiwayat();
  }

  Future<void> deleteRiwayat(int idPenjualan) async {
    try {
      // Mengambil instance Supabase client
      final supabase = Supabase.instance.client;

      // Menghapus semua detail transaksi terkait dari tabel 'detail_penjualan'
      await supabase
          .from('detail_penjualan')
          .delete()
          .eq('id_penjualan', idPenjualan);

      // Menghapus transaksi utama dari tabel 'penjualan'
      await supabase.from('penjualan').delete().eq('id_penjualan', idPenjualan);

      // Memperbarui daftar riwayat transaksi setelah penghapusan berhasil
      refreshRiwayat();

      // Menampilkan notifikasi bahwa riwayat berhasil dihapus
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Riwayat transaksi berhasil dihapus')),
      );
    } catch (e) {
      // Menampilkan notifikasi jika terjadi error saat menghapus
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Terjadi kesalahan: $e'),
      ));
    }
  }

  void confirmDeleteRiwayat(int idPenjualan) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: const Text(
              'Apakah Anda yakin ingin menghapus riwayat transaksi ini?'),
          actions: [
            // Tombol batal, hanya menutup dialog
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
              },
              child: const Text('Batal'),
            ),

            // Tombol hapus, memanggil fungsi deleteRiwayat setelah menutup dialog
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog sebelum menghapus
                deleteRiwayat(idPenjualan); // Panggil fungsi hapus
              },
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF6F8FC), // Mengatur warna latar belakang halaman
      body: RefreshIndicator(
        // Widget untuk menarik daftar riwayat transaksi agar diperbarui
        onRefresh:
            refreshRiwayat, // Memanggil fungsi refreshRiwayat saat di-refresh
        child: transaksiList.isEmpty // Cek apakah daftar transaksi kosong
            ? Center(
                // Jika kosong, tampilkan pesan "Belum ada riwayat transaksi"
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // const Icon(Icons.history, size: 80, color: Colors.grey), // (Dikomentari, bisa diaktifkan jika ingin menampilkan ikon)
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada riwayat transaksi',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                // Jika ada data, tampilkan daftar transaksi
                padding: const EdgeInsets.all(12),
                itemCount: transaksiList
                    .length, // Jumlah transaksi yang akan ditampilkan
                itemBuilder: (context, index) {
                  final transaksi =
                      transaksiList[index]; // Ambil transaksi berdasarkan index
                  final penjualan =
                      transaksi['penjualan']; // Data transaksi utama
                  final details =
                      transaksi['details']; // Detail produk dalam transaksi

                  // Mengambil nama pelanggan, jika tidak tersedia tampilkan 'User'
                  final namaPelanggan = penjualan['pelanggan'] != null
                      ? penjualan['pelanggan']['nama_pelanggan']
                      : 'User';

                  return Card(
                    margin: const EdgeInsets.only(
                        bottom: 16), // Jarak antar kartu transaksi
                    elevation:
                        4, // Memberikan efek shadow agar tampilan lebih menarik
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          12), // Membuat kartu lebih membulat
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Menampilkan nama pelanggan
                          Text(
                            'Pelanggan: $namaPelanggan',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF091057),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Menampilkan tanggal dan total harga transaksi
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Tanggal: ${penjualan['tgl_penjualan']}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Total: Rp ${penjualan['total_harga'].toDouble().toStringAsFixed(0)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFEC8305),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(), // Garis pemisah antara informasi transaksi dan detail produk
                          const SizedBox(height: 8),

                          // Menampilkan daftar produk dalam transaksi
                          ListView.builder(
                            shrinkWrap:
                                true, // Agar ListView tidak mengambil seluruh tinggi layar
                            physics:
                                const NeverScrollableScrollPhysics(), // Menonaktifkan scroll dalam ListView ini agar tidak bentrok dengan ListView utama
                            itemCount:
                                details.length, // Jumlah produk dalam transaksi
                            itemBuilder: (context, detailIndex) {
                              final detail = details[detailIndex];
                              // Mengambil nama produk, jika tidak tersedia tampilkan "Produk tidak ditemukan"
                              final namaProduk = detail['produk'] != null
                                  ? detail['produk']['nama_produk']
                                  : 'Produk tidak ditemukan';

                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Jika produk adalah item pertama dalam daftar, tampilkan label "Produk :"
                                    if (detailIndex == 0)
                                      Text(
                                        'Produk :',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF091057),
                                        ),
                                      ),

                                    // Menampilkan nama produk dan jumlah yang dibeli
                                    Text(
                                      '$namaProduk | ${detail['jumlah_produk']}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),

                                    // Menampilkan subtotal harga produk
                                    Text(
                                      'Subtotal : Rp ${detail['subtotal'].toDouble().toStringAsFixed(0)}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blueGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),

                          // Tombol untuk menghapus transaksi
                          ElevatedButton.icon(
                            onPressed: () => confirmDeleteRiwayat(penjualan[
                                'id_penjualan']), // Konfirmasi sebelum menghapus
                            icon: const Icon(Icons.delete),
                            label: const Text('Hapus Riwayat'),
                            style: ElevatedButton.styleFrom(
                              iconColor: Colors
                                  .red, // Warna ikon merah untuk menandakan tindakan hapus
                              backgroundColor: Colors
                                  .white, // Warna tombol putih agar kontras
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
