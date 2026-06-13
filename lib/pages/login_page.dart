import 'package:flutter/material.dart';

import '../widgets/widgets.dart';

class _DemoAccount {
  const _DemoAccount({
    required this.label,
    required this.username,
    required this.password,
    required this.icon,
  });

  final String label;
  final String username;
  final String password;
  final IconData icon;
}

const _demoAccounts = [
  _DemoAccount(
    label: 'Anggota Harapan Baru',
    username: 'pak_hendra',
    password: 'password123',
    icon: AppIcons.navProfile,
  ),
  _DemoAccount(
    label: 'Primary Harapan Baru',
    username: 'primary_harapanbaru',
    password: 'password123',
    icon: AppIcons.navMembers,
  ),
  _DemoAccount(
    label: 'Secondary Admin',
    username: 'secondary_admin',
    password: 'password123',
    icon: AppIcons.navKoperasi,
  ),
];

class LoginPage extends StatefulWidget {
  const LoginPage({
    required this.loading,
    required this.onLogin,
    required this.onRegister,
    this.errorMessage,
    super.key,
  });

  final bool loading;
  final String? errorMessage;
  final Future<void> Function(String identifier, String password) onLogin;
  final Future<void> Function(String name, String email, String password)
  onRegister;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final username = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  var registerMode = false;
  var obscurePassword = true;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    username.dispose();
    password.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/onboarding_farm.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(70),
                    Colors.black.withAlpha(18),
                    AppColors.background.withAlpha(245),
                  ],
                  stops: const [0, 0.42, 0.72],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                            child: _HeroHeader(registerMode: registerMode),
                          ),
                          const Spacer(),
                          _AuthPanel(
                            registerMode: registerMode,
                            loading: widget.loading,
                            errorMessage: widget.errorMessage,
                            formKey: formKey,
                            name: name,
                            email: email,
                            username: username,
                            password: password,
                            confirmPassword: confirmPassword,
                            obscurePassword: obscurePassword,
                            onToggleMode: () =>
                                setState(() => registerMode = !registerMode),
                            onTogglePassword: () => setState(
                              () => obscurePassword = !obscurePassword,
                            ),
                            onSubmit: submit,
                            onUseDemoAccount: useDemoAccount,
                            nameText: nameText,
                            identifierText: identifierText,
                            emailText: emailText,
                            passwordText: passwordText,
                            confirmPasswordText: confirmPasswordText,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String? nameText(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Nama wajib diisi';
    if (text.length < 2) return 'Nama minimal 2 karakter';
    return null;
  }

  String? identifierText(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Email atau username wajib diisi';
    return null;
  }

  String? emailText(String? value) {
    final text = value?.trim() ?? '';
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)
        ? null
        : 'Email tidak valid';
  }

  String? passwordText(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Password wajib diisi';
    if (text.length < 6) return 'Password minimal 6 karakter';
    return null;
  }

  String? confirmPasswordText(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Konfirmasi password wajib diisi';
    if (text != password.text) return 'Konfirmasi password tidak sama';
    return null;
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    if (registerMode) {
      await widget.onRegister(
        name.text.trim(),
        email.text.trim(),
        password.text,
      );
      return;
    }
    await widget.onLogin(username.text.trim(), password.text);
  }

  void useDemoAccount(_DemoAccount account) {
    setState(() {
      registerMode = false;
      obscurePassword = false;
      username.text = account.username;
      password.text = account.password;
    });
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.registerMode});

  final bool registerMode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Image.asset(
              'assets/logo_nobg.png',
              height: 46,
              width: 46,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            Text(
              'VivaJauh',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        Text(
          registerMode ? 'Daftar akun koperasi' : 'Masuk ke VivaJauh',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            height: 1.02,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          registerMode
              ? 'Buat akun untuk petugas dan koperasi yang akan dikelola.'
              : 'Untuk pencatatan pakan, ternak, sync data, dan laporan koperasi.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white.withAlpha(230),
            height: 1.42,
          ),
        ),
      ],
    );
  }
}

class _AuthPanel extends StatelessWidget {
  const _AuthPanel({
    required this.registerMode,
    required this.loading,
    required this.formKey,
    required this.name,
    required this.email,
    required this.username,
    required this.password,
    required this.confirmPassword,
    required this.obscurePassword,
    required this.onToggleMode,
    required this.onTogglePassword,
    required this.onSubmit,
    required this.onUseDemoAccount,
    required this.nameText,
    required this.identifierText,
    required this.emailText,
    required this.passwordText,
    required this.confirmPasswordText,
    this.errorMessage,
  });

  final bool registerMode;
  final bool loading;
  final String? errorMessage;
  final GlobalKey<FormState> formKey;
  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController username;
  final TextEditingController password;
  final TextEditingController confirmPassword;
  final bool obscurePassword;
  final VoidCallback onToggleMode;
  final VoidCallback onTogglePassword;
  final Future<void> Function() onSubmit;
  final ValueChanged<_DemoAccount> onUseDemoAccount;
  final String? Function(String?) nameText;
  final String? Function(String?) identifierText;
  final String? Function(String?) emailText;
  final String? Function(String?) passwordText;
  final String? Function(String?) confirmPasswordText;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        22 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _PanelHeader(registerMode: registerMode),
            const SizedBox(height: 20),
            if (registerMode) ...[
              _LabeledField(
                label: 'Nama',
                controller: name,
                validator: nameText,
              ),
              const SizedBox(height: 13),
              _LabeledField(
                label: 'Email aktif',
                controller: email,
                validator: emailText,
                keyboardType: TextInputType.emailAddress,
              ),
            ] else
              _LabeledField(
                label: 'Email atau username',
                controller: username,
                validator: identifierText,
              ),
            const SizedBox(height: 13),
            _LabeledField(
              label: 'Password',
              controller: password,
              validator: passwordText,
              obscureText: obscurePassword,
              onSubmitted: registerMode ? null : (_) => onSubmit(),
              suffixIcon: IconButton(
                onPressed: onTogglePassword,
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: AppColors.muted,
                  size: 20,
                ),
              ),
            ),
            if (registerMode) ...[
              const SizedBox(height: 13),
              _LabeledField(
                label: 'Konfirmasi password',
                controller: confirmPassword,
                validator: confirmPasswordText,
                obscureText: obscurePassword,
                onSubmitted: (_) => onSubmit(),
              ),
            ] else ...[
              const SizedBox(height: 14),
              _DemoAccountPicker(
                accounts: _demoAccounts,
                onSelected: loading ? null : onUseDemoAccount,
              ),
            ],
            if (errorMessage != null) ...[
              const SizedBox(height: 14),
              _ErrorBanner(
                message: errorMessage!.replaceFirst('Exception: ', ''),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              height: 54,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(registerMode ? 'Daftar' : 'Masuk'),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: loading ? null : onToggleMode,
                child: Text(
                  registerMode
                      ? 'Sudah punya akun? Login'
                      : 'Belum punya akun? Register',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.registerMode});

  final bool registerMode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          registerMode ? 'Buat akun' : 'Login',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          registerMode
              ? 'Isi data dasar koperasi'
              : 'Masukkan akun yang terdaftar',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.text,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          onFieldSubmitted: onSubmitted,
          textInputAction: onSubmitted == null
              ? TextInputAction.next
              : TextInputAction.done,
          decoration: InputDecoration(
            hintText: label,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DemoAccountPicker extends StatelessWidget {
  const _DemoAccountPicker({required this.accounts, required this.onSelected});

  final List<_DemoAccount> accounts;
  final ValueChanged<_DemoAccount>? onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Akun demo',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.text,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        for (final account in accounts) ...[
          _DemoAccountButton(
            account: account,
            onPressed: onSelected == null ? null : () => onSelected!(account),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _DemoAccountButton extends StatelessWidget {
  const _DemoAccountButton({required this.account, required this.onPressed});

  final _DemoAccount account;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          children: [
            Icon(account.icon, size: 18, color: AppColors.primaryDark),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    account.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    account.username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withAlpha(18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger.withAlpha(55)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.danger,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
