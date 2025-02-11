// Import berbagai package yang digunakan dalam halaman login.
import 'package:coba/main.dart'; // Import main.dart untuk navigasi ke MainScreen setelah login.
import 'package:flutter/material.dart'; // Import library Flutter untuk membangun UI.
import 'package:google_fonts/google_fonts.dart'; // Untuk menggunakan font khusus dari Google Fonts.
import 'package:supabase_flutter/supabase_flutter.dart'; // Library Supabase untuk autentikasi.

// Kelas Login sebagai StatefulWidget untuk menangani perubahan state.
class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

// State dari halaman Login.
class _LoginState extends State<Login> {
  // Controller untuk menangani input email dan password.
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Global key untuk validasi form.
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading =
      false; // Menunjukkan apakah proses login sedang berlangsung.
  bool _isPasswordVisible = false; // Menyimpan status visibility password.

  // Fungsi untuk menangani login.
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return; // Jika form tidak valid, hentikan eksekusi fungsi.
    }

    setState(() {
      _isLoading = true; // Mengaktifkan indikator loading.
    });

    final email = _emailController.text.trim(); // Mengambil input email.
    final password = _passwordController.text; // Mengambil input password.

    try {
      // Melakukan autentikasi dengan Supabase.
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session != null) {
        _showSnackBar('Login berhasil!'); // Menampilkan notifikasi berhasil.

        // Navigasi ke halaman MainScreen setelah login sukses.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const MainScreen(selectedIndex: 1),
          ),
        );
      } else {
        _showSnackBar(
            'Login gagal. Periksa email dan password Anda!'); // Notifikasi jika login gagal.
      }
    } catch (error) {
      _showSnackBar(
          'Error: ${error.toString()}'); // Menampilkan error jika terjadi masalah.
    } finally {
      setState(() {
        _isLoading =
            false; // Mematikan indikator loading setelah proses login selesai.
      });
    }
  }

  // Fungsi untuk menampilkan SnackBar sebagai notifikasi.
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Mengatur warna latar belakang halaman.
      body: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.all(24.0), // Memberikan padding pada tampilan.
          child: Form(
            key: _formKey, // Menghubungkan form dengan key validasi.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 50), // Memberikan jarak ke atas.
                Text(
                  "Selamat Datang",
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF091057),
                  ),
                ),
                const SizedBox(height: 5), // Jarak antara teks.
                RichText(
                  text: TextSpan(
                    children: <InlineSpan>[
                      TextSpan(
                        text: 'Halaman Login ',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFFDBD3D3),
                        ),
                      ),
                      TextSpan(
                        text: 'Kasir.in',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFEC8305),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),

                // Label dan input untuk email.
                Text("Email",
                    style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF074799))),
                TextFormField(
                  controller:
                      _emailController, // Menghubungkan input dengan controller.
                  validator: (value) => value!.isEmpty
                      ? 'Isi bagian email'
                      : null, // Validasi input.
                  decoration: InputDecoration(
                    prefixIcon:
                        const Icon(Icons.person, color: Color(0xFF074799)),
                    hintText: "masukkan email",
                    hintStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey),
                    border: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),

                const SizedBox(height: 20),
                // Label dan input untuk password.
                Text("Password",
                    style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF074799))),
                TextFormField(
                  controller:
                      _passwordController, // Menghubungkan input dengan controller.
                  obscureText:
                      !_isPasswordVisible, // Menyembunyikan password jika tidak ditampilkan.
                  validator: (value) => value!.isEmpty
                      ? 'Isi bagian password'
                      : null, // Validasi input.
                  decoration: InputDecoration(
                    prefixIcon:
                        const Icon(Icons.lock, color: Color(0xFF074799)),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: const Color(0xFF074799)),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible =
                              !_isPasswordVisible; // Toggle visibility password.
                        });
                      },
                    ),
                    hintText: "masukkan password",
                    hintStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey),
                    border: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),

                const SizedBox(
                    height: 70), // Memberikan jarak sebelum tombol login.

                // Tombol Login.
                SizedBox(
                  width: double.infinity, // Tombol melebar ke seluruh layar.
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : _login, // Menjalankan fungsi login saat tombol ditekan.
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF091057),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            color: Colors
                                .white) // Menampilkan loading jika sedang proses login.
                        : Text("Login",
                            style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                                color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Fungsi yang dipanggil saat widget dihancurkan untuk menghindari memory leak.
  @override
  void dispose() {
    _emailController.dispose(); // Menghapus controller email.
    _passwordController.dispose(); // Menghapus controller password.
    super.dispose();
  }
}
