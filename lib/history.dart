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
      final supabase = Supabase.instance.client;
      final penjualanResponse = await supabase
          .from('penjualan')
          .select('*, pelanggan(nama_pelanggan)')
          .order('tgl_penjualan', ascending: false)
          .order('id_penjualan', ascending: false);

      if (penjualanResponse.isNotEmpty) {
        final futures = penjualanResponse.map((penjualan) async {
          final detailResponse = await supabase
              .from('detail_penjualan')
              .select('*, produk(nama_produk)')
              .eq('id_penjualan', penjualan['id_penjualan'])
              .order('id_detail', ascending: false);

          return {
            'penjualan': penjualan,
            'details': detailResponse,
          };
        }).toList();

        final results = await Future.wait(futures);

        setState(() {
          transaksiList = results;
        });
      }
    } catch (e) {
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
      final supabase = Supabase.instance.client;
      await supabase.from('detail_penjualan').delete().eq('id_penjualan', idPenjualan);
      await supabase.from('penjualan').delete().eq('id_penjualan', idPenjualan);
      refreshRiwayat();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Riwayat transaksi berhasil dihapus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Terjadi kesalahan: $e'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: RefreshIndicator(
        onRefresh: refreshRiwayat,
        child: transaksiList.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: transaksiList.length,
                itemBuilder: (context, index) {
                  final transaksi = transaksiList[index];
                  final penjualan = transaksi['penjualan'];
                  final details = transaksi['details'];

                  final namaPelanggan = penjualan['pelanggan'] != null
                      ? penjualan['pelanggan']['nama_pelanggan']
                      : 'User';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pelanggan: $namaPelanggan',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF074799),
                            ),
                          ),
                          const SizedBox(height: 8),
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
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: details.length,
                            itemBuilder: (context, detailIndex) {
                              final detail = details[detailIndex];
                              final namaProduk = detail['produk'] != null
                                  ? detail['produk']['nama_produk']
                                  : 'Produk tidak ditemukan';

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (detailIndex == 0)
                                      Text(
                                        'Produk :',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    Text(
                                      '$namaProduk | ${detail['jumlah_produk']}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      'Total : Rp ${detail['subtotal'].toDouble().toStringAsFixed(0)}',
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
                          ElevatedButton.icon(
                            onPressed: () => deleteRiwayat(penjualan['id_penjualan']),
                            icon: const Icon(Icons.delete),
                            label: const Text('Hapus Riwayat'),
                            style: ElevatedButton.styleFrom(
                              iconColor: Colors.red,
                              backgroundColor: Colors.white,
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
