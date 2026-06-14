import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../i18n/i18n_service.dart';

/// 登录/注册页 — 国别区号 + 手机号 + 验证码
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _countryCode = '+86';
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  bool _codeSent = false;
  bool _isSending = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入手机号码')),
      );
      return;
    }

    setState(() => _isSending = true);

    final auth = context.read<AuthProvider>();
    final success = await auth.sendCode(
      countryCode: _countryCode,
      phone: phone,
    );

    if (mounted) {
      setState(() {
        _isSending = false;
        if (success) {
          _codeSent = true;
        }
      });

      if (!success && auth.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.errorMessage!)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(t('login'))),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo / Title
              const Icon(
                Icons.show_chart,
                size: 48,
                color: Color(0xFF5DA3F3),
              ),
              const SizedBox(height: 8),
              Text(
                'Wallstreet',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: const Color(0xFFBADBFF),
                    ),
              ),
              const SizedBox(height: 32),
              // 国别区号选择
              DropdownButtonFormField<String>(
                value: _countryCode,
                decoration: InputDecoration(labelText: t('country_code')),
                items: const [
                  DropdownMenuItem(value: '+86', child: Text('+86 中国')),
                  DropdownMenuItem(value: '+852', child: Text('+852 香港')),
                  DropdownMenuItem(value: '+853', child: Text('+853 澳门')),
                  DropdownMenuItem(value: '+886', child: Text('+886 台湾')),
                  DropdownMenuItem(value: '+1', child: Text('+1 美国/加拿大')),
                  DropdownMenuItem(value: '+7', child: Text('+7 俄罗斯')),
                  DropdownMenuItem(value: '+33', child: Text('+33 法国')),
                  DropdownMenuItem(value: '+34', child: Text('+34 西班牙')),
                  DropdownMenuItem(value: '+39', child: Text('+39 意大利')),
                  DropdownMenuItem(value: '+44', child: Text('+44 英国')),
                  DropdownMenuItem(value: '+49', child: Text('+49 德国')),
                  DropdownMenuItem(value: '+60', child: Text('+60 马来西亚')),
                  DropdownMenuItem(value: '+63', child: Text('+63 菲律宾')),
                  DropdownMenuItem(value: '+81', child: Text('+81 日本')),
                  DropdownMenuItem(value: '+82', child: Text('+82 韩国')),
                  DropdownMenuItem(value: '+84', child: Text('+84 越南')),
                  DropdownMenuItem(value: '+91', child: Text('+91 印度')),
                  DropdownMenuItem(value: '+971', child: Text('+971 阿联酋')),
                ],
                onChanged: (v) => setState(() => _countryCode = v!),
              ),
              const SizedBox(height: 16),
              // 手机号输入
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: t('enter_phone'),
                  hintText: t('enter_phone'),
                ),
              ),
              const SizedBox(height: 16),
              // 发送验证码按钮
              if (!_codeSent)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSending ? null : _sendCode,
                    child: _isSending
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(t('send_code')),
                  ),
                ),
              if (_codeSent) ...[
                // 验证码输入
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: t('enter_code'),
                    hintText: t('enter_code'),
                  ),
                ),
                const SizedBox(height: 16),
                // 错误信息
                if (auth.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      auth.errorMessage!,
                      style: const TextStyle(
                        color: Color(0xFFFF5757),
                        fontSize: 13,
                      ),
                    ),
                  ),
                if (auth.isLoading)
                  const CircularProgressIndicator(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: auth.isLoading
                        ? null
                        : () async {
                            final success = await auth.loginWithPhone(
                              countryCode: _countryCode,
                              phone: _phoneController.text.trim(),
                              code: _codeController.text.trim(),
                            );
                            if (success && mounted) {
                              Navigator.pop(context);
                            }
                          },
                    child: Text(t('login')),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
