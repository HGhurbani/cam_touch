// lib/core/services/location_service.dart

import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

class LocationService {
  Future<Position?> getCurrentLocation() async {
    try {
      // تحقق مما إذا كانت خدمات الموقع ممكّنة
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        // يمكن فتح إعدادات الموقع هنا إذا أردت
        await Geolocator.openLocationSettings();
        return null;
      }

      // طلب أذونات الموقع
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied.');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied, we cannot request permissions.');
        // يمكن توجيه المستخدم لفتح إعدادات التطبيق يدوياً
        await Geolocator.openAppSettings();
        return null;
      }

      // الحصول على الموقع الحالي بدقة عالية
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      return position;
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }
}