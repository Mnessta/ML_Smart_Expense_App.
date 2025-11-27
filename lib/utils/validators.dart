/// Data validation utilities
class Validators {
  /// Validates email address
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    
    final RegExp emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  /// Validates password
  static String? password(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    
    return null;
  }

  /// Validates strong password (optional)
  static String? strongPassword(String? value) {
    final String? basic = password(value, minLength: 8);
    if (basic != null) return basic;
    
    if (value == null) return null;
    
    final bool hasUpperCase = value.contains(RegExp(r'[A-Z]'));
    final bool hasLowerCase = value.contains(RegExp(r'[a-z]'));
    final bool hasDigits = value.contains(RegExp(r'[0-9]'));
    final bool hasSpecialChar = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    
    if (!hasUpperCase || !hasLowerCase || !hasDigits || !hasSpecialChar) {
      return 'Password must contain uppercase, lowercase, number, and special character';
    }
    
    return null;
  }

  /// Validates amount/money
  static String? amount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }
    
    final double? parsed = double.tryParse(value.trim());
    
    if (parsed == null) {
      return 'Please enter a valid number';
    }
    
    if (parsed <= 0) {
      return 'Amount must be greater than 0';
    }
    
    if (parsed > 999999999) {
      return 'Amount is too large';
    }
    
    return null;
  }

  /// Validates required field
  static String? required(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates name
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    if (value.trim().length > 50) {
      return 'Name is too long';
    }
    
    return null;
  }

  /// Validates phone number (basic)
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    
    final RegExp phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
    
    if (!phoneRegex.hasMatch(value.trim().replaceAll(RegExp(r'[\s-]'), ''))) {
      return 'Please enter a valid phone number';
    }
    
    return null;
  }

  /// Validates date
  static String? date(DateTime? value) {
    if (value == null) {
      return 'Date is required';
    }
    
    final DateTime now = DateTime.now();
    final DateTime maxDate = now.add(const Duration(days: 365));
    
    if (value.isAfter(maxDate)) {
      return 'Date cannot be more than 1 year in the future';
    }
    
    return null;
  }

  /// Validates category selection
  static String? category(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please select a category';
    }
    return null;
  }

  /// Validates payment method
  static String? paymentMethod(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please select a payment method';
    }
    return null;
  }

  /// Validates note/description (optional field)
  static String? note(String? value, {int maxLength = 500}) {
    if (value != null && value.length > maxLength) {
      return 'Note must be less than $maxLength characters';
    }
    return null;
  }
}

















