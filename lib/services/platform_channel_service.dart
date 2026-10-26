import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Dịch vụ Platform Channels theo đúng chuẩn Slide 36 & 37 VKU Week 8
/// Giao tiếp trực tiếp giữa Flutter (Dart) và Host OS (Android Kotlin / iOS Swift)
class PlatformChannelService {
  static const MethodChannel platform = MethodChannel('vn.edu.vku/device_info');

  /// Đọc mức pin phần trăm từ phần cứng thiết bị (Slide 37)
  static Future<int> getBatteryLevel() async {
    if (kIsWeb) {
      return 100; // Giả lập 100% khi chạy trên môi trường Web / Cloudflare
    }
    try {
      final int? result = await platform.invokeMethod<int>('getBatteryLevel');
      return result ?? -1;
    } on PlatformException catch (_) {
      return -1;
    } catch (_) {
      return -1;
    }
  }

  /// Kích hoạt rung phản hồi xúc giác (Haptic Feedback) khi lưu giao dịch thành công
  static void triggerHaptic() {
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }
}
