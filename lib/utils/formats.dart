import 'package:intl/intl.dart';

class AppFormats {
  const AppFormats._();

  static final _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );
  static final _number = NumberFormat.decimalPattern('id_ID');

  static const monthsShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];
  static const daysShort = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  static const daysLong = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu',
  ];
  static const monthsLong = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  static String _two(int v) => v.toString().padLeft(2, '0');

  static String rupiah(num value) => _rupiah.format(value);

  static String rupiahCompact(num value) {
    final abs = value.abs();
    final prefix = value < 0 ? '-' : '';
    if (abs >= 1000000000) return '${prefix}Rp ${(abs / 1000000000).toStringAsFixed(1)}M';
    if (abs >= 1000000) return '${prefix}Rp ${(abs / 1000000).toStringAsFixed(1)}jt';
    if (abs >= 1000) return '${prefix}Rp ${(abs / 1000).toStringAsFixed(0)}rb';
    return rupiah(value);
  }
  static String number(num value) => _number.format(value);
  static String kg(num value) => '${_number.format(value)} kg';
  static String ekor(num value) => '${_number.format(value)} ekor';
  static String signed(num value) =>
      value >= 0 ? '+${_number.format(value)}' : _number.format(value);

  static String dayDateShort(DateTime value) {
    final l = value.toLocal();
    return '${daysShort[l.weekday - 1]}, ${l.day} ${monthsShort[l.month - 1]}';
  }

  static String dateShort(DateTime value) {
    final l = value.toLocal();
    return '${_two(l.day)} ${monthsShort[l.month - 1]}, ${_two(l.hour)}:${_two(l.minute)}';
  }

  static String dateLong(DateTime value) {
    final l = value.toLocal();
    return '${daysLong[l.weekday - 1]}, ${l.day} ${monthsLong[l.month - 1]} ${l.year} · ${_two(l.hour)}:${_two(l.minute)}';
  }

  static String dateDay(DateTime value) {
    final l = value.toLocal();
    return '${_two(l.day)} ${monthsShort[l.month - 1]} ${l.year}';
  }

  static String time(DateTime value) {
    final l = value.toLocal();
    return '${_two(l.hour)}:${_two(l.minute)}';
  }

  static String delta(Duration value) {
    final d = value.isNegative ? Duration.zero : value;
    if (d.inSeconds < 60) return '${d.inSeconds} d';
    if (d.inMinutes < 60) return '${d.inMinutes} m';
    if (d.inHours < 24) {
      final minutes = d.inMinutes % 60;
      return minutes == 0 ? '${d.inHours} j' : '${d.inHours} j $minutes m';
    }
    final hours = d.inHours % 24;
    return hours == 0 ? '${d.inDays} hr' : '${d.inDays} hr $hours j';
  }
}
