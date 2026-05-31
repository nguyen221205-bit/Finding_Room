class Formatters {
  static String formatCurrency(int value) {
    if (value >= 1000000) {
      final double millions = value / 1000000;
      final String formatted = millions == millions.roundToDouble()
          ? millions.toStringAsFixed(0)
          : millions.toStringAsFixed(1);
      return '$formatted triệu';
    }

    final String digits = value.abs().toString();
    final StringBuffer out = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final int indexFromEnd = digits.length - i;
      out.write(digits[i]);
      if (indexFromEnd > 1 && indexFromEnd % 3 == 1) {
        out.write('.');
      }
    }
    final String sign = value < 0 ? '-' : '';
    return '$sign$out ₫';
  }

  static String pricePerMonth(int price) => '${formatCurrency(price)}/tháng';
}
