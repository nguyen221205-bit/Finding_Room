import 'package:url_launcher/url_launcher.dart';

class Launchers {
  static Future<bool> callPhone(String phone) async {
    final Uri uri = Uri(scheme: 'tel', path: phone);
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<bool> openMap(double? lat, double? lng, String address) async {
    final String query = Uri.encodeComponent(address);
    final Uri googleMapsUrl = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$query",
    );

    if (lat != null && lng != null) {
      final Uri coordsUrl = Uri.parse(
        "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
      );
      if (await canLaunchUrl(coordsUrl)) {
        await launchUrl(coordsUrl, mode: LaunchMode.externalApplication);
        return true;
      }
    }

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  }
}
