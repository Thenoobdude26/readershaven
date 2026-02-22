import 'package:flutter/material.dart';
import 'main.dart'; // your existing home page file

// ─────────────────────────────────────────────────────────────
// Entry point — swap main() here OR in home_page.dart, not both
// ─────────────────────────────────────────────────────────────
void main() {
  runApp(const ReaderSHavenApp());
}

class ReaderSHavenApp extends StatelessWidget {
  const ReaderSHavenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReaderSHaven',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B4226),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Georgia',
      ),
      // Start at the login/signup screen
      home: const LoginSignupPage(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Login / Sign-up Page
// ─────────────────────────────────────────────────────────────

class LoginSignupPage extends StatefulWidget {
  const LoginSignupPage({super.key});

  @override
  State<LoginSignupPage> createState() => _LoginSignupPageState();
}

class _LoginSignupPageState extends State<LoginSignupPage>
    with SingleTickerProviderStateMixin {
  // Toggle between Login and Sign-up forms
  bool _isLogin = true;

  // Form key for basic validation
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _usernameCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _switchMode() {
    setState(() => _isLogin = !_isLogin);
    _fadeCtrl.forward(from: 0);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simulate network call — replace with real auth logic
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() => _isLoading = false);

    // Navigate to Home, removing login from back stack
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const HomePage(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  // ── Input decoration helper ──
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70, fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.white60, size: 20),
      filled: true,
      fillColor: Colors.white.withOpacity(0.08),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFFFD261), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Warm dark gradient background
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A0A00), Color(0xFF3B1F0A), Color(0xFF0F0B6D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Logo & App name ──
                  _buildHeader(),

                  const SizedBox(height: 36),

                  // ── Tab toggle ──
                  _buildToggle(),

                  const SizedBox(height: 28),

                  // ── Form card ──
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: _buildForm(),
                  ),

                  const SizedBox(height: 20),

                  // ── Divider + social ──
                  _buildSocialSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Widgets ─────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      children: [
        // Book icon in a glowing circle
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.07),
            border: Border.all(color: const Color(0xFFFFD261).withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD261).withOpacity(0.2),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(
            Icons.menu_book_rounded,
            color: Color(0xFFFFD261),
            size: 44,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          "ReaderSHaven",
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Your literary haven awaits",
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 13,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  Widget _buildToggle() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          _toggleButton("Sign In", isActive: _isLogin, onTap: () {
            if (!_isLogin) _switchMode();
          }),
          _toggleButton("Sign Up", isActive: !_isLogin, onTap: () {
            if (_isLogin) _switchMode();
          }),
        ],
      ),
    );
  }

  Widget _toggleButton(String label,
      {required bool isActive, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFFFD261) : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFF1A0A00) : Colors.white60,
              fontWeight:
                  isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Username — only shown during sign-up
          if (!_isLogin) ...[
            TextFormField(
              controller: _usernameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Username", Icons.person_outline),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? "Enter a username" : null,
            ),
            const SizedBox(height: 14),
          ],

          // Email
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration("Email", Icons.email_outlined),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return "Enter your email";
              if (!v.contains('@')) return "Enter a valid email";
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Password
          TextFormField(
            controller: _passwordCtrl,
            obscureText: _obscurePassword,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration("Password", Icons.lock_outline).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white38,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return "Enter your password";
              if (v.length < 6) return "Password must be at least 6 characters";
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Confirm password — only on sign-up
          if (!_isLogin) ...[
            TextFormField(
              controller: _confirmCtrl,
              obscureText: _obscureConfirm,
              style: const TextStyle(color: Colors.white),
              decoration:
                  _inputDecoration("Confirm Password", Icons.lock_outline)
                      .copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white38,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              validator: (v) {
                if (v != _passwordCtrl.text) return "Passwords do not match";
                return null;
              },
            ),
            const SizedBox(height: 14),
          ],

          // Forgot password (login only)
          if (_isLogin)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: const Text(
                  "Forgot password?",
                  style: TextStyle(color: Color(0xFFFFD261), fontSize: 12),
                ),
              ),
            ),

          const SizedBox(height: 8),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD261),
                foregroundColor: const Color(0xFF1A0A00),
                disabledBackgroundColor: const Color(0xFFFFD261).withOpacity(0.5),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xFF1A0A00),
                      ),
                    )
                  : Text(
                      _isLogin ? "SIGN IN" : "CREATE ACCOUNT",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: 1,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: Divider(color: Colors.white.withOpacity(0.15), thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                "or continue with",
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
              ),
            ),
            Expanded(
                child: Divider(color: Colors.white.withOpacity(0.15), thickness: 1)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _socialButton(Icons.g_mobiledata_rounded, "Google"),
            const SizedBox(width: 16),
            _socialButton(Icons.facebook_rounded, "Facebook"),
          ],
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: _switchMode,
          child: RichText(
            text: TextSpan(
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
              children: [
                TextSpan(
                    text: _isLogin
                        ? "Don't have an account? "
                        : "Already have an account? "),
                TextSpan(
                  text: _isLogin ? "Sign Up" : "Sign In",
                  style: const TextStyle(
                    color: Color(0xFFFFD261),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _socialButton(IconData icon, String label) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 20, color: Colors.white70),
      label: Text(label,
          style: const TextStyle(color: Colors.white70, fontSize: 13)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        side: BorderSide(color: Colors.white.withOpacity(0.2)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}