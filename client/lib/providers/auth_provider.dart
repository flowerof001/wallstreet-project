import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class AuthProvider extends ChangeNotifier {
  User _user = User.guest();
  bool _isLoggedIn = false;
  bool _isLoading = false;
  DateTime? _sessionStart;
  bool _showLoginDialog = false;
  String? _errorMessage;

  User get user => _user;
  bool get isLoggedIn => _isLoggedIn;
  bool get isGuest => _user.isGuest;
  bool get isLoading => _isLoading;
  bool get showLoginDialog => _showLoginDialog;
  String? get errorMessage => _errorMessage;

  /// 初始化：尝试从持久化 token 恢复会话
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final savedUser = await UserService.getMe();
      if (savedUser != null) {
        _user = savedUser;
        _isLoggedIn = true;
        _sessionStart = DateTime.now();
      } else {
        startGuestSession();
      }
    } catch (e) {
      startGuestSession();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 游客进入：开始计时180秒
  void startGuestSession() {
    _sessionStart = DateTime.now();
    _showLoginDialog = false;
    notifyListeners();
  }

  /// 检查游客停留时长，>=180秒触发登录弹框
  void checkSessionDuration() {
    if (_isLoggedIn || _sessionStart == null || _showLoginDialog) return;

    final elapsed = DateTime.now().difference(_sessionStart!);
    if (elapsed.inSeconds >= 180) {
      _showLoginDialog = true;
      notifyListeners();
    }
  }

  /// 关闭登录弹框
  void dismissLoginDialog() {
    _showLoginDialog = false;
    notifyListeners();
  }

  /// 发送手机验证码
  Future<bool> sendCode({
    required String countryCode,
    required String phone,
  }) async {
    try {
      await UserService.sendCode(countryCode, phone);
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = '发送验证码失败: $e';
      notifyListeners();
      return false;
    }
  }

  /// 手机验证码登录/注册
  Future<bool> loginWithPhone({
    required String countryCode,
    required String phone,
    required String code,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await UserService.loginWithCode(
        countryCode,
        phone,
        code,
      );

      _isLoggedIn = true;
      _showLoginDialog = false;
      _user = user;
      _sessionStart = DateTime.now();
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = '登录失败: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 登出
  Future<void> logout() async {
    await UserService.clearToken();
    _isLoggedIn = false;
    _user = User.guest();
    startGuestSession();
    notifyListeners();
  }

  /// 注销帐号
  Future<bool> deleteAccount() async {
    _isLoading = true;
    notifyListeners();

    try {
      await UserService.deleteAccount();
      _isLoggedIn = false;
      _user = User.guest();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = '注销帐号失败: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 修改密码
  Future<Map<String, dynamic>> changePassword({
    String? oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (newPassword != confirmPassword) {
      return {'success': false, 'message': '两次密码不一致'};
    }
    if (newPassword.length < 6 || newPassword.length > 32) {
      return {'success': false, 'message': '密码长度必须为6-32位'};
    }

    _isLoading = true;
    notifyListeners();

    try {
      final result = await UserService.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': e.toString()};
    }
  }
}
