import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:styleai/core/config/api_config.dart';

class AudioAnalysisApi {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(minutes: 3),
      receiveTimeout: const Duration(minutes: 3),
    ),
  );

  Future<dynamic> analyzeFile(
    PlatformFile file,
    String daw,
    Map<String, double> feeling,
  ) async { 
    debugPrint('Feeling: ${feeling} DAW: ${daw}');
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        file.bytes!,
        filename: file.name,
      ),
      'softwareType': daw,
      'feeling': feeling
    });

    final response = await _dio.post(
      '${ApiConfig.baseUrl}/songs/analyze',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );

    return response.data;
  }
}