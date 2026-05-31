import 'package:hive/hive.dart';

class BusinessCodeGenerator {
  /// Tự động tạo mã hiển thị (business code) duy nhất theo định dạng tuần tự.
  /// Ví dụ: USR00001, ROOM00015, VER00007, RPT00001.
  ///
  /// [prefix] là tiền tố của mã hiển thị (ví dụ: 'USR', 'ROOM', 'VER', 'RPT').
  /// [box] là Hive box chứa các bản ghi hiện tại để quét mã lớn nhất.
  /// [codeExtractor] là hàm để trích xuất mã hiển thị từ bản ghi trong box.
  static String generate({
    required String prefix,
    required Box<dynamic> box,
    required String? Function(dynamic entry) codeExtractor,
  }) {
    int maxNumber = 0;

    for (final dynamic entry in box.values) {
      final String? existingCode = codeExtractor(entry);
      if (existingCode != null && existingCode.startsWith(prefix)) {
        final String numPart = existingCode.substring(prefix.length);
        final int? val = int.tryParse(numPart);
        if (val != null && val > maxNumber) {
          maxNumber = val;
        }
      }
    }

    final int nextNumber = maxNumber + 1;
    final String formattedNumber = nextNumber.toString().padLeft(5, '0');
    return '$prefix$formattedNumber';
  }
}
