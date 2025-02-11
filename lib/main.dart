// Import berbagai package yang digunakan dalam aplikasi.
import 'package:coba/history.dart'; // Import halaman Riwayat
import 'package:coba/login.dart'; // Import halaman Login
import 'package:coba/pesanan.dart'; // Import halaman Pesanan
import 'package:flutter/material.dart'; // Import library Flutter untuk UI
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts untuk kustomisasi teks
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase untuk backend database
import 'package:coba/dashboard.dart'; // Import halaman Dashboard
import 'package:coba/produk.dart'; // Import halaman Produk
import 'package:coba/pelanggan.dart'; // Import halaman Pelanggan

// Fungsi main untuk menjalankan aplikasi Flutter
Future<void> main() async {
  // Inisialisasi Supabase dengan URL dan anonKey
  await Supabase.initialize(
    url: 'https://opziotddijuwbwmpawjl.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9wemlvdGRkaWp1d2J3bXBhd2psIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzg3MTQxNzAsImV4cCI6MjA1NDI5MDE3MH0.YETTUqofugClG9kqbWK1I0mqLrFxaTqe4WPSXVz85nI',
  );

  // Menjalankan aplikasi dengan widget utama MyApp
  runApp(const MyApp());
}

// Kelas utama aplikasi Flutter
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Menyembunyikan banner debug
      title: 'Flutter Demo', // Judul aplikasi
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF3674B5)), // Tema warna utama
        useMaterial3: true, // Menggunakan Material 3
      ),
      home: const Login(), // Halaman pertama yang muncul adalah halaman Login
    );
  }
}

// Kelas untuk tampilan utama setelah login berhasil
class MainScreen extends StatefulWidget {
  final int selectedIndex;
  const MainScreen({super.key, this.selectedIndex = 0}); // Default index = 0

  @override
  State<MainScreen> createState() => _MainScreenState();
}

// State untuk MainScreen
class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex; // Menggunakan nilai dari parameter
  }

  // Daftar halaman yang bisa ditampilkan dalam bottom navigation bar
  final List<Widget> _pages = [
    const Produk(), // Halaman Produk
    const Pesanan(), // Halaman Pesanan
    const Riwayat(), // Halaman Riwayat
    const Pelanggan(), // Halaman Pelanggan
    const Dashboard(), // Halaman Dashboard atau User
  ];

  // Daftar judul untuk setiap halaman
  final List<String> _titles = [
    "Kasir.in",
    "Pesanan",
    "Riwayat",
    "Pelanggan",
    "User",
  ];

  // Fungsi untuk mengubah halaman saat item di bottom navigation diklik
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Fungsi logout
  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Login()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0 ? "Kasir.in" : _titles[_selectedIndex],
          style: _selectedIndex == 0
              ? GoogleFonts.poppins(
                  fontSize: 26, // Ukuran lebih besar untuk halaman Produk
                  fontWeight: FontWeight.bold,
                  color: const Color(
                      0xFFEC8305), // Warna khusus untuk halaman Produk
                )
              : GoogleFonts.poppins( // Style default untuk halaman lain
                  fontSize: 24, 
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF024CAA), // Warna default
                ),
        ),

        backgroundColor: Colors.transparent, // Membuat AppBar transparan
        elevation: 0, // Menghilangkan bayangan AppBar
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Color(0xFF091057),
            ),
            onPressed: _logout,
            tooltip: "Logout",
          ),
        ],
      ),
      body: _pages[
          _selectedIndex], // Menampilkan halaman sesuai indeks yang dipilih
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            label: 'Produk'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_basket),
            label: 'Pesanan'),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Riwayat'),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Pelanggan'),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_outlined),
            label: 'User'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF091057),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}
