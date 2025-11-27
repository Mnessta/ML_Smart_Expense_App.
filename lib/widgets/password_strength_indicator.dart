import 'package:flutter/material.dart';

/// Password strength levels
enum PasswordStrength {
  weak,
  medium,
  strong,
}

/// Password requirement checker
class PasswordRequirement {
  final String label;
  final bool Function(String) validator;
  bool isValid = false;

  PasswordRequirement({
    required this.label,
    required this.validator,
  });
}

/// Widget that displays password strength and requirements
class PasswordStrengthIndicator extends StatefulWidget {
  final String password;
  final bool showOnlyWhenNotEmpty;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    this.showOnlyWhenNotEmpty = true,
  });

  @override
  State<PasswordStrengthIndicator> createState() =>
      _PasswordStrengthIndicatorState();
}

class _PasswordStrengthIndicatorState
    extends State<PasswordStrengthIndicator> {
  List<PasswordRequirement> _buildRequirements() {
    return [
      PasswordRequirement(
        label: 'At least 8 characters',
        validator: (pwd) => pwd.length >= 8,
      ),
      PasswordRequirement(
        label: 'Contains uppercase letter',
        validator: (pwd) => pwd.contains(RegExp(r'[A-Z]')),
      ),
      PasswordRequirement(
        label: 'Contains lowercase letter',
        validator: (pwd) => pwd.contains(RegExp(r'[a-z]')),
      ),
      PasswordRequirement(
        label: 'Contains number',
        validator: (pwd) => pwd.contains(RegExp(r'[0-9]')),
      ),
      PasswordRequirement(
        label: 'Contains special character',
        validator: (pwd) =>
            pwd.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=~`\[\]\\/]')),
      ),
    ];
  }

  List<PasswordRequirement> _getEvaluatedRequirements() {
    final requirements = _buildRequirements();
    for (var requirement in requirements) {
      requirement.isValid = requirement.validator(widget.password);
    }
    return requirements;
  }

  PasswordStrength _getPasswordStrength(List<PasswordRequirement> requirements) {
    final validCount = requirements.where((r) => r.isValid).length;
    if (validCount < 3) {
      return PasswordStrength.weak;
    } else if (validCount < 5) {
      return PasswordStrength.medium;
    } else {
      return PasswordStrength.strong;
    }
  }

  Color _getStrengthColor(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return Colors.red;
      case PasswordStrength.medium:
        return Colors.orange;
      case PasswordStrength.strong:
        return Colors.green;
    }
  }

  String _getStrengthText(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.medium:
        return 'Medium';
      case PasswordStrength.strong:
        return 'Strong';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showOnlyWhenNotEmpty && widget.password.isEmpty) {
      return const SizedBox.shrink();
    }

    final requirements = _getEvaluatedRequirements();
    final strength = _getPasswordStrength(requirements);
    final strengthColor = _getStrengthColor(strength);
    final strengthText = _getStrengthText(strength);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Strength indicator bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: requirements.where((r) => r.isValid).length /
                        requirements.length,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                strengthText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: strengthColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Requirements list
          ...requirements.map((requirement) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      requirement.isValid
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      size: 16,
                      color: requirement.isValid
                          ? Colors.green
                          : Colors.grey[400],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        requirement.label,
                        style: TextStyle(
                          fontSize: 12,
                          color: requirement.isValid
                              ? Colors.green[700]
                              : Colors.grey[600],
                          decoration: requirement.isValid
                              ? TextDecoration.none
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

