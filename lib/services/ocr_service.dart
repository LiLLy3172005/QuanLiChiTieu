import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Dịch vụ OCR nhận diện văn bản On-Device hoàn toàn OFFLINE
/// Sử dụng Google ML Kit Text Recognition (Chuẩn Slide 41 & 42)
class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Nhận diện văn bản từ file ảnh chụp hóa đơn / ảnh chụp màn hình tin nhắn
  Future<String> recognizeTextFromImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      // Fallback an toàn nếu có lỗi xử lý file ảnh
      return '';
    }
  }

  /// Giải phóng tài nguyên bộ nhớ theo đúng nguyên tắc Mobile Memory Management (Slide 29 & 46)
  void dispose() {
    _textRecognizer.close();
  }
}
