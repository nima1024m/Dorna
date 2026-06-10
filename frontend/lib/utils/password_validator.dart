class PasswordValidator {
  static bool hasMinLength(String value, {int minLength = 8}) {
    return value.length >= minLength;
  }

  static bool hasNumber(String value) {
    return RegExp(r"[0-9]").hasMatch(value);
  }

  static bool hasLower(String value) {
    return RegExp(r"[a-z]").hasMatch(value);
  }

  static bool hasUpper(String value) {
    return RegExp(r"[A-Z]").hasMatch(value);
  }

  static bool isValid(String value, {int minLength = 8}) {
    return hasUpper(value) &&
        hasLower(value) &&
        hasNumber(value) &&
        hasMinLength(value, minLength: minLength);
  }

  static String? validate(String? value, {int minLength = 8}) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (!isValid(value, minLength: minLength)) return 'Password is not valid';
    return null;
  }
}
