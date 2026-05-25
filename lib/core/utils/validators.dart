class Validators {
  static String? requiredField(String? value, {String label = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  static String? email(String? value) {
    final String? required = requiredField(value, label: 'Email');
    if (required != null) return required;
    final String v = value!.trim();
    final RegExp re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!re.hasMatch(v)) return 'Please enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    final String? required = requiredField(value, label: 'Password');
    if (required != null) return required;
    if (value!.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? positiveNumber(String? value, {String label = 'Value'}) {
    final String? required = requiredField(value, label: label);
    if (required != null) return required;

    final num? parsed = num.tryParse(value!.trim());
    if (parsed == null) return '$label must be a valid number';
    if (parsed <= 0) return '$label must be greater than 0';
    return null;
  }

  static String? phone(String? value) {
    final String? required = requiredField(value, label: 'Phone number');
    if (required != null) return required;

    final String trimmed = value!.trim();
    final RegExp re = RegExp(r'^\+?[0-9\s]{8,15}$');
    if (!re.hasMatch(trimmed)) return 'Please enter a valid phone number';
    return null;
  }

  static String? identityNumber(String? value) {
    final String? required = requiredField(value, label: 'Identity number');
    if (required != null) return required;

    final String trimmed = value!.trim();
    if (trimmed.length < 6) return 'Identity number is too short';
    return null;
  }

  static String? minLength(
    String? value, {
    required String label,
    int minLength = 3,
  }) {
    final String? required = requiredField(value, label: label);
    if (required != null) return required;
    if (value!.trim().length < minLength) {
      return '$label must be at least $minLength characters';
    }
    return null;
  }
}
