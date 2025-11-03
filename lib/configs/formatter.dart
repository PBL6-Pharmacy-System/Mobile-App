import 'package:intl/intl.dart';

class Formatter {
  /// Định dạng ngày theo kiểu yyyy/MM/dd
  static String formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('yyyy/MM/dd').format(date);
  }

  /// Định dạng ngày giờ chi tiết (vd: 2025/10/30 - 14:35)
  static String formatDateTime(DateTime? date) {
    if (date == null) return '';
    return DateFormat('yyyy/MM/dd - HH:mm').format(date);
  }

  /// Định dạng thời gian dạng giờ:phút
  static String formatTime(DateTime? date) {
    if (date == null) return '';
    return DateFormat('HH:mm').format(date);
  }

  /// Định dạng số (vd: 10000 -> 10,000)
  static String formatNumber(num? value) {
    if (value == null) return '0';
    return NumberFormat('#,###').format(value);
  }

  /// Định dạng tiền (vd: 10000 -> 10,000₫)
  static String formatCurrency(num? value) {
    if (value == null) return '0₫';
    return '${NumberFormat('#,###').format(value)}₫';
  }

  static String formatCompact(num value) {
    if (value >= 1_000_000_000_000) {
      return "${(value / 1_000_000_000_000).toStringAsFixed(1)}B"; // B = nghìn tỷ
    } else if (value >= 1_000_000_000) {
      return "${(value / 1_000_000_000).toStringAsFixed(1)}T"; // T = tỷ
    } else if (value >= 1_000_000) {
      return "${(value / 1_000_000).toStringAsFixed(1)}M"; // M = triệu
    } else if (value >= 1_000) {
      return "${(value / 1_000).toStringAsFixed(1)}K"; // K = nghìn
    } else {
      return value.toString();
    }
  }

  static String getInitials(String name) {
    if (name.trim().isEmpty) return '';

    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }

    final first = parts[0][0].toUpperCase();
    final last = parts[parts.length - 1][0].toUpperCase();

    return '$first$last';
  }

  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) {
      return 'Vừa xong';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    } else if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return '$weeks tuần trước';
    } else if (diff.inDays < 365) {
      final months = (diff.inDays / 30).floor();
      return '$months tháng trước';
    } else {
      final years = (diff.inDays / 365).floor();
      return '$years năm trước';
    }
  }

  static int getDaysSinceQuit(DateTime quitDate) {
    final now = DateTime.now();
    final difference = now.difference(quitDate).inDays;
    return difference;
  }

  static String formatPercent(num value) {
    final str = value.toStringAsFixed(10);
    final index = str.indexOf('.');
    final cut = index == -1
        ? str
        : str.substring(0, (index + 3).clamp(0, str.length));

    final cleaned = cut.replaceFirst(RegExp(r'\.?0+$'), '');
    return '$cleaned%';
  }
}
