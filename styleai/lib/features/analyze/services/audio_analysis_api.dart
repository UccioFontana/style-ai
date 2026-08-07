import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

class AudioAnalysisApi {
  final Dio _dio = Dio();

  Future<dynamic> analyzeFile(PlatformFile file) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        file.bytes!,
        filename: file.name,
      ),
    });

    final response = await _dio.post(
      'http://localhost:8000/songs/analyze',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );

    return response.data;
  }
}