import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
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
    List<String> instruments,
    Map<String, double> feeling,
  ) async {
    MultipartFile multipartFile;

    if (kIsWeb) {
      if (file.bytes == null) {
        throw Exception('File non valido su web: bytes non disponibili.');
      }

      multipartFile = MultipartFile.fromBytes(
        file.bytes!,
        filename: file.name,
      );
    } else {
      if (file.path != null) {
        multipartFile = await MultipartFile.fromFile(
          file.path!,
          filename: file.name,
        );
      } else if (file.bytes != null) {
        multipartFile = MultipartFile.fromBytes(
          file.bytes!,
          filename: file.name,
        );
      } else {
        throw Exception('File non valido: path e bytes non disponibili.');
      }
    }

    final formData = FormData.fromMap({
      'file': multipartFile,
      'softwareType': daw,
      'instruments': jsonEncode(instruments),
      'feeling': jsonEncode(feeling),
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