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
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

// State untuk MainScreen
class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // Indeks halaman yang sedang aktif

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
    "Produk",
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
          _titles[_selectedIndex], // Menampilkan judul sesuai halaman aktif
          style: GoogleFonts.poppins(
            // Menggunakan font Poppins
            fontSize: 24,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color.fromARGB(255, 41, 83, 128),), // Tambahkan ikon logout
            onPressed: _logout,
            tooltip: "Logout",
          ),
        ],
        // backgroundColor: Theme.of(context)
        //     .colorScheme
        //     .inversePrimary, // Warna latar belakang AppBar
      ),
      body: _pages[
          _selectedIndex], // Menampilkan halaman sesuai indeks yang dipilih
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag_outlined),
              label: 'Produk'), // Item untuk Produk
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_basket),
              label: 'Pesanan'), // Item untuk Pesanan
          BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'Riwayat'), // Item untuk Riwayat
          BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Pelanggan'), // Item untuk Pelanggan
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_outlined),
              label: 'User'), // Item untuk User
        ],
        currentIndex: _selectedIndex, // Menandai item yang sedang aktif
        selectedItemColor: const Color(0xFF3674B5), // Warna item yang dipilih
        unselectedItemColor: Colors.grey, // Warna item yang tidak dipilih
        onTap: _onItemTapped, // Memanggil fungsi saat item diklik
      ),
    );
  }
}
