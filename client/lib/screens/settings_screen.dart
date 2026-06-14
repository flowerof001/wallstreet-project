import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../i18n/i18n_service.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(t('settings'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile card
          if (auth.isLoggedIn)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 32,
                      backgroundColor: Color(0xFF0A2E67),
                      child: Icon(Icons.person, size: 36, color: Color(0xFF5DA3F3)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${auth.user.countryCode} ${auth.user.phone}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFBADBFF),
                      ),
                    ),
                    if (auth.user.country != null)
                      Text(
                        'Country: ${auth.user.country}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8899AA),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          if (!auth.isLoggedIn)
            Card(
              child: ListTile(
                leading: const Icon(Icons.login),
                title: Text(t('login')),
                onTap: () => Navigator.pushNamed(context, '/login'),
              ),
            ),
          const SizedBox(height: 16),
          Card(
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: Text(t('change_password')),
                onTap: () => _showChangePasswordDialog(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Color(0xFFC13636)),
                title: Text(t('delete_account'),
                    style: const TextStyle(color: Color(0xFFC13636))),
                onTap: () => _showDeleteAccountDialog(context),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPwdCtl = TextEditingController();
    final newPwdCtl = TextEditingController();
    final confirmCtl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('change_password')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPwdCtl,
              obscureText: true,
              decoration: InputDecoration(labelText: t('current_password')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPwdCtl,
              obscureText: true,
              decoration: InputDecoration(labelText: t('new_password')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmCtl,
              obscureText: true,
              decoration: InputDecoration(labelText: t('confirm_password')),
            ),
            const SizedBox(height: 8),
            Text(
              t('password_rule'),
              style: const TextStyle(fontSize: 11, color: Color(0xFF8899AA)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              final auth = context.read<AuthProvider>();
              final result = await auth.changePassword(
                oldPassword:
                    oldPwdCtl.text.isEmpty ? null : oldPwdCtl.text,
                newPassword: newPwdCtl.text,
                confirmPassword: confirmCtl.text,
              );
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result?['message'] ?? 'Done',
                    ),
                  ),
                );
              }
            },
            child: Text(t('submit')),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('delete_account_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC13636),
            ),
            onPressed: () async {
              final auth = context.read<AuthProvider>();
              await auth.deleteAccount();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(t('confirm')),
          ),
        ],
      ),
    );
  }
}
