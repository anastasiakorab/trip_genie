class FakeUser {
  final String name;
  final String email;

  FakeUser({
    required this.name,
    required this.email,
  });
}

class FakeAuthService {
  static FakeUser? currentUser;

  static final Map<String, Map<String, String>> _users = {};

  static bool get isLoggedIn => currentUser != null;

  static String? signUp({
    required String name,
    required String email,
    required String password,
  }) {
    final cleanName = name.trim();
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    if (cleanName.isEmpty) return 'Please enter your name.';

    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      return 'Please enter a valid email.';
    }

    if (cleanPassword.length < 6) {
      return 'Password must be at least 6 characters.';
    }

    _users[cleanEmail] = {
      'name': cleanName,
      'password': cleanPassword,
    };

    currentUser = FakeUser(
      name: cleanName,
      email: cleanEmail,
    );

    return null;
  }

  static String? login({
    required String email,
    required String password,
  }) {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    if (cleanEmail.isEmpty || cleanPassword.isEmpty) {
      return 'Please enter email and password.';
    }

    if (!_users.containsKey(cleanEmail)) {
      return 'Account not found. Please sign up first.';
    }

    if (_users[cleanEmail]!['password'] != cleanPassword) {
      return 'Incorrect password.';
    }

    currentUser = FakeUser(
      name: _users[cleanEmail]!['name']!,
      email: cleanEmail,
    );

    return null;
  }

  static void logout() {
    currentUser = null;
  }
}