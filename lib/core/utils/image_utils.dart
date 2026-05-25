class ImageUtils {
  static bool isNetworkImage(String path) {
    final String value = path.trim().toLowerCase();
    return value.startsWith('http://') || value.startsWith('https://');
  }

  static bool isUsablePath(String path) => path.trim().isNotEmpty;
}
