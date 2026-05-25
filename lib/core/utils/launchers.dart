import 'package:url_launcher/url_launcher.dart';

class Launchers {
  static Future<bool> callPhone(String phone) async {
    final Uri uri = Uri(scheme: 'tel', path: phone);
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
