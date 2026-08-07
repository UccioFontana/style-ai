class MetricsMapper {
  static List<MapEntry<String, String>> buildRows(dynamic responseData) {
    final metrics = _getTechnicalMetrics(responseData);

    dynamic v(List<String> path) {
      dynamic current = metrics;

      for (final key in path) {
        if (current is Map && current.containsKey(key)) {
          current = current[key];
        } else {
          return null;
        }
      }

      return current;
    }

    return [
      MapEntry(
        'LUFS integrated',
        format(v(['loudness', 'lufs_integrated']), suffix: ' LUFS'),
      ),
      MapEntry(
        'LUFS short-term',
        _formatLufsList(v(['loudness', 'lufs_short_term'])),
      ),
      MapEntry(
        'LUFS momentary',
        _formatLufsList(v(['loudness', 'lufs_momentary'])),
      ),
      MapEntry(
        'True Peak',
        format(v(['peaks', 'true_peak_dbtp']), suffix: ' dBTP'),
      ),
      MapEntry(
        'Peak massimo',
        format(v(['peaks', 'max_peak_dbfs']), suffix: ' dBFS'),
      ),
      MapEntry(
        'Peak massimo lineare',
        format(v(['peaks', 'max_peak_linear'])),
      ),
      MapEntry(
        'RMS',
        format(v(['dynamics', 'rms_dbfs']), suffix: ' dBFS'),
      ),
      MapEntry(
        'RMS lineare',
        format(v(['dynamics', 'rms_linear'])),
      ),
      MapEntry(
        'Crest Factor',
        format(v(['dynamics', 'crest_factor_db']), suffix: ' dB'),
      ),
      MapEntry(
        'Crest Factor lineare',
        format(v(['dynamics', 'crest_factor_linear'])),
      ),
      MapEntry(
        'Durata',
        format(v(['audio_properties', 'duration', 'formatted'])),
      ),
      MapEntry(
        'Sample rate',
        format(v(['audio_properties', 'sample_rate']), suffix: ' Hz'),
      ),
      MapEntry(
        'Canali',
        format(v(['audio_properties', 'channels'])),
      ),
      MapEntry(
        'Bit depth',
        format(v(['audio_properties', 'bit_depth']), suffix: ' bit'),
      ),
      MapEntry(
        'Formato',
        format(v(['audio_properties', 'format'])),
      ),
      MapEntry(
        'Subtype',
        format(v(['audio_properties', 'subtype'])),
      ),
      MapEntry(
        'Clipping detection',
        v(['clipping', 'clipping_detected']) == true ? 'Sì' : 'No',
      ),
      MapEntry(
        'Campioni clipped',
        format(v(['clipping', 'clipped_samples'])),
      ),
      MapEntry(
        'Clipping %',
        format(v(['clipping', 'clipping_percentage']), suffix: ' %'),
      ),
      MapEntry(
        'Headroom residua',
        format(v(['headroom', 'headroom_db']), suffix: ' dB'),
      ),
    ];
  }

  static String extractAiReview(dynamic responseData) {
    if (responseData is! Map) {
      return '';
    }

    final aiReview = responseData['ai_mix_review'];

    if (aiReview is Map && aiReview['text'] != null) {
      return aiReview['text'].toString();
    }

    return '';
  }

  static dynamic getTechnicalValue(
    dynamic responseData,
    List<String> path,
  ) {
    final metrics = _getTechnicalMetrics(responseData);
    dynamic current = metrics;

    for (final key in path) {
      if (current is Map && current.containsKey(key)) {
        current = current[key];
      } else {
        return null;
      }
    }

    return current;
  }

  static String format(dynamic value, {String suffix = ''}) {
    if (value == null) {
      return 'Non disponibile';
    }

    return '$value$suffix';
  }

  static dynamic _getTechnicalMetrics(dynamic responseData) {
    if (responseData is Map && responseData['technical_metrics'] is Map) {
      return responseData['technical_metrics'];
    }

    return {};
  }

  static String _formatLufsList(dynamic values) {
    if (values == null || values is! List || values.isEmpty) {
      return 'Non disponibile';
    }

    final lufsValues = values
        .map((item) => item is Map ? item['lufs'] : null)
        .where((value) => value != null)
        .map((value) => double.tryParse(value.toString()))
        .whereType<double>()
        .toList();

    if (lufsValues.isEmpty) {
      return 'Non disponibile';
    }

    final min = lufsValues.reduce((a, b) => a < b ? a : b);
    final max = lufsValues.reduce((a, b) => a > b ? a : b);
    final avg = lufsValues.reduce((a, b) => a + b) / lufsValues.length;

    return 'Avg: ${avg.toStringAsFixed(2)} LUFS | '
        'Min: ${min.toStringAsFixed(2)} | '
        'Max: ${max.toStringAsFixed(2)} | '
        '${lufsValues.length} finestre';
  }
}