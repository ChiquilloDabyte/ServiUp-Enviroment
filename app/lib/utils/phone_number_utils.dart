final RegExp _colombianMobilePattern = RegExp(r'^3\d{9}$');

String normalizeColombianMobile(String value) {
  var digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('57') && digits.length == 12) {
    digits = digits.substring(2);
  }
  if (!_colombianMobilePattern.hasMatch(digits)) {
    throw const FormatException(
      'Ingresa un celular colombiano válido de 10 dígitos.',
    );
  }
  return '+57$digits';
}

String localColombianMobile(String? value) {
  if (value == null) return '';
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('57') && digits.length == 12) {
    return digits.substring(2);
  }
  return digits.length == 10 ? digits : '';
}
