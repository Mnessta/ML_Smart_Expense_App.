import 'package:flutter_test/flutter_test.dart';
import 'package:ml_smart_expense_track/utils/validators.dart';

void main() {
  group('Validators', () {
    test('email validation', () {
      expect(Validators.email(null), equals('Email is required'));
      expect(Validators.email(''), equals('Email is required'));
      expect(Validators.email('invalid'), equals('Please enter a valid email address'));
      expect(Validators.email('test@example.com'), isNull);
    });

    test('password validation', () {
      expect(Validators.password(null), equals('Password is required'));
      expect(Validators.password('12345'), equals('Password must be at least 6 characters'));
      expect(Validators.password('123456'), isNull);
    });

    test('amount validation', () {
      expect(Validators.amount(null), equals('Amount is required'));
      expect(Validators.amount(''), equals('Amount is required'));
      expect(Validators.amount('invalid'), equals('Please enter a valid number'));
      expect(Validators.amount('0'), equals('Amount must be greater than 0'));
      expect(Validators.amount('100'), isNull);
    });

    test('required field validation', () {
      expect(Validators.required(null), equals('Field is required'));
      expect(Validators.required(''), equals('Field is required'));
      expect(Validators.required('value'), isNull);
    });
  });
}

















