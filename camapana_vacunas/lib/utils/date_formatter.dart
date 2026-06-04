class DateFormatter {
  /// Retorna la fecha y hora en formato DD/MM/YYYY HH:MM
  static String formatDateTime(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    
    return "$day/$month/$year $hour:$minute";
  }

  /// Retorna solo la fecha en formato DD/MM/YYYY
  static String formatDateOnly(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    
    return "$day/$month/$year";
  }
}