import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

final deviceServiceProvider = Provider<DeviceService>((ref) {
  return DeviceService();
});

class DeviceService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _notificationsInitialized = false;

  static Future<void> initNotifications() async {
    if (_notificationsInitialized) return;
    const settings = InitializationSettings(
      iOS: DarwinInitializationSettings(),
    );
    await _notifications.initialize(settings);
    _notificationsInitialized = true;
  }

  Future<bool> ensureCameraPermission() async {
    if (!Platform.isIOS) return true;
    final status = await Permission.camera.status;
    if (status.isPermanentlyDenied) return false;
    return true;
  }

  Future<bool> requestNotificationPermission() async {
    if (!Platform.isIOS) return true;
    await initNotifications();
    final result = await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return result ?? false;
  }

  Future<void> openAppSettingsPage() async => openAppSettings();

  Future<List<String>?> scanDocumentRaw() async {
    final paths = await CunningDocumentScanner.getPictures(
          isGalleryImportAllowed: false,
        ) ??
        [];
    return paths.isEmpty ? null : paths;
  }

  Future<String> saveScannedImages(List<String> sourcePaths) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final scansDir = Directory('${appDocDir.path}/scans');
    if (!await scansDir.exists()) await scansDir.create(recursive: true);

    final finalPaths = <String>[];
    for (int i = 0; i < sourcePaths.length; i++) {
      final fileName = 'scan_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      final dest = '${scansDir.path}/$fileName';
      await File(sourcePaths[i]).copy(dest);
      finalPaths.add(dest);
    }
    return finalPaths.join(',');
  }

  Future<void> deleteImage(String imagePath) async {
    final file = File(imagePath);
    if (await file.exists()) await file.delete();
  }

  Future<void> showSaveSuccessNotification(String sheetTitle) async {
    await initNotifications();
    const details = NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    await _notifications.show(
      0,
      'Sheet music saved',
      sheetTitle,
      details,
    );
  }
}
