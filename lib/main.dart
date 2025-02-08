import 'package:coba/history.dart';
import 'package:coba/login.dart';
import 'package:coba/pesanan.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:coba/dashboard.dart';
import 'package:coba/produk.dart';
import 'package:coba/pelanggan.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://opziotddijuwbwmpawjl.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9wemlvdGRkaWp1d2J3bXBhd2psIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzg3MTQxNzAsImV4cCI6MjA1NDI5MDE3MH0.YETTUqofugClG9kqbWK1I0mqLrFxaTqe4WPSXVz85nI',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3674B5)),
        useMaterial3: true,
      ),
      home: const Login(), // Ubah agar pertama kali muncul halaman login
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const Produk(),
    const Pesanan(), // Bisa diganti dengan halaman pesanan
    const Riwayat(), // Bisa diganti dengan halaman riwayat    
    const Pelanggan(),
    const Dashboard(),
  ];

  final List<String> _titles = [
    "Produk",
    "Pesanan",
    "Riwayat",
    "Pelanggan",
    "User",
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), label: 'Produk'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_basket), label: 'Pesanan'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Pelanggan'),
          BottomNavigationBarItem(icon: Icon(Icons.verified_user_rounded), label: 'User'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF3674B5),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}
