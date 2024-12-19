import 'package:url_launcher/url_launcher.dart';

class NavigationService {
  static Future<void> openGoogleMapsNavigation(double latitude, double longitude) async {
    final Uri googleMapsUri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving');
    if (await canLaunchUrl(googleMapsUri)) {
      await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch Google Maps';
    }
  }

  static Future<void> openWazeNavigation(double latitude, double longitude) async {
    final Uri wazeUri = Uri.parse('https://waze.com/ul?ll=$latitude,$longitude&navigate=yes');
    if (await canLaunchUrl(wazeUri)) {
      await launchUrl(wazeUri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch Waze';
    }
  }

  static Future<void> openDefaultMapsNavigation(double latitude, double longitude) async {
    final Uri mapsUri = Uri.parse('geo:$latitude,$longitude?q=$latitude,$longitude');
    if (await canLaunchUrl(mapsUri)) {
      await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch default maps';
    }
  }
}
