import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/constants.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/services/user_session.dart';
import 'package:mobile/screens/root_shell.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLogin = true;
  bool _loading = false;
  String? _error;

  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  void _goToShell(Map<String, dynamic> user) {
    final username = user['username'] as String? ??
        (_emailController.text.split('@').first);
    final email = user['email'] as String? ?? _emailController.text;

    UserSession.loggedInUser = username;
    UserSession.email = email;
    UserSession.persist();

    // Sync saved places from backend after login
    UserSession.syncFromBackend();

    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const RootShell()));
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _loading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _error = 'Email and password are required.';
        _loading = false;
      });
      return;
    }

    if (!_isLogin) {
      final name = _nameController.text.trim();
      final username = _usernameController.text.trim();
      if (name.isEmpty || username.isEmpty) {
        setState(() {
          _error = 'Name and username are required.';
          _loading = false;
        });
        return;
      }

      try {
        final data = await AuthService.register(
          email: email,
          username: username,
          password: password,
          fullName: name,
        );
        if (!mounted) return;
        _goToShell(data['user'] as Map<String, dynamic>);
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    } else {
      try {
        final data = await AuthService.login(
          email: email,
          password: password,
        );
        if (!mounted) return;
        _goToShell(data['user'] as Map<String, dynamic>);
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  void _guestLogin() {
    UserSession.loggedInUser = 'Guest Explorer';
    UserSession.email = 'guest@yatrasathi.com';
    UserSession.persist();
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const RootShell()));
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Logo + title ──────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset('yatrasathi_logo.jpeg',
                          width: 72, height: 72, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 14),
                    Text('Yatra Sathi',
                        style: Theme.of(context).textTheme.displayLarge),
                    const SizedBox(height: 6),
                    Text('Nepal road trips, curated and designed.',
                        style: GoogleFonts.inter(
                            fontSize: 14, color: kGray),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // ── Toggle ────────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kBorder),
                ),
                child: Row(
                  children: [
                    _toggleButton('Sign In', isActive: _isLogin,
                        onTap: () => setState(() {
                              _isLogin = true;
                              _error = null;
                            })),
                    _toggleButton('Sign Up', isActive: !_isLogin,
                        onTap: () => setState(() {
                              _isLogin = false;
                              _error = null;
                            })),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // ── Fields ────────────────────────────────────────────────
              if (!_isLogin) ...[
                _field(_nameController, 'Full Name', 'Your full name',
                    icon: Icons.person_outline),
                const SizedBox(height: 12),
                _field(_usernameController, 'Username', 'e.g. himalayan_traveler',
                    icon: Icons.alternate_email),
                const SizedBox(height: 12),
              ],
              _field(_emailController, 'Email', 'you@example.com',
                  icon: Icons.email_outlined,
                  type: TextInputType.emailAddress),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: '••••••••',
                  prefixIcon:
                      const Icon(Icons.lock_outline, color: kGray, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: kGray,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),

              // ── Error ─────────────────────────────────────────────────
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: Colors.red.shade600, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!,
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.red.shade700)),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 22),

              // ── Submit ────────────────────────────────────────────────
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_isLogin ? 'Sign In' : 'Create Account',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600, fontSize: 15)),
              ),

              const SizedBox(height: 16),
              const Row(children: [
                Expanded(child: Divider(color: kBorder)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('or', style: TextStyle(color: kGray)),
                ),
                Expanded(child: Divider(color: kBorder)),
              ]),
              const SizedBox(height: 16),

              // ── Guest ─────────────────────────────────────────────────
              OutlinedButton.icon(
                onPressed: _guestLogin,
                icon: const Icon(Icons.explore_outlined,
                    color: kDark, size: 18),
                label: Text('Continue as Guest',
                    style: GoogleFonts.inter(
                        color: kDark, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: kBorder),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toggleButton(String label,
      {required bool isActive, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? kOrange : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: isActive ? Colors.white : kGray,
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    String hint, {
    IconData? icon,
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null
            ? Icon(icon, color: kGray, size: 20)
            : null,
      ),
    );
  }
}
