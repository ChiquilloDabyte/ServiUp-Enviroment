import 'package:intl/intl.dart';

final appDateFormat = DateFormat('dd/MM/yyyy HH:mm');

String formatDateTime(DateTime dateTime) => appDateFormat.format(dateTime);

String formatCurrency(double value) => '\$${value.toStringAsFixed(2)}';
