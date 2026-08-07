class FrequencyMapper {
  static const List<String> _bandKeys = [
    'sub',
    'low',
    'low_mid',
    'mid',
    'presence',
    'high',
    'air',
  ];

  static List<TonalBandRow> buildTonalRows(dynamic responseData) {
    final frequencyAnalysis = _getFrequencyAnalysis(responseData);
    final bands = frequencyAnalysis['bands'];

    if (bands is! Map) {
      return [];
    }

    return _bandKeys.map((key) {
      final band = bands[key];

      if (band is! Map) {
        return TonalBandRow.empty(key);
      }

      return TonalBandRow(
        key: key,
        label: _stringValue(band['label']),
        range: _formatRange(band['range_hz']),
        energyPercent: _doubleValue(band['energy_percent']),
        energyText: _formatPercent(band['energy_percent']),
        status: _formatStatus(band['status']),
        avgDb: _formatDb(band['avg_db']),
        p10Db: _formatDb(band['p10_db']),
        p50Db: _formatDb(band['p50_db']),
        p90Db: _formatDb(band['p90_db']),
        peakDb: _formatDb(band['peak_db']),
        variationDb: _formatDb(band['variation_db']),
      );
    }).toList();
  }

  static String extractTonalProfile(dynamic responseData) {
    return _stringValue(
      _getOverall(responseData)['tonal_profile'],
      fallback: 'Non disponibile',
    );
  }

  static String extractDominantBand(dynamic responseData) {
    return _stringValue(
      _getOverall(responseData)['dominant_band'],
      fallback: 'Non disponibile',
    );
  }

  static String extractSpectralCentroid(dynamic responseData) {
    final value = _getOverall(responseData)['spectral_centroid_hz'];
    return value == null ? 'Non disponibile' : '$value Hz';
  }

  static String extractLowEndPercent(dynamic responseData) {
    return _formatPercent(_getOverall(responseData)['low_end_percent']);
  }

  static String extractHighEndPercent(dynamic responseData) {
    return _formatPercent(_getOverall(responseData)['high_end_percent']);
  }

  static String extractConfidence(dynamic responseData) {
    final quality = _getQuality(responseData);
    final label = quality['confidence_label'];
    final score = quality['confidence_score'];

    if (label == null && score == null) {
      return 'Non disponibile';
    }

    return '$label ($score)';
  }

  static List<String> extractWarnings(dynamic responseData) {
    final frequencyAnalysis = _getFrequencyAnalysis(responseData);
    final warnings = frequencyAnalysis['warnings'];

    if (warnings is! List) {
      return [];
    }

    return warnings.map((item) => item.toString()).toList();
  }

  static List<MapEntry<String, String>> buildFrameStatsRows(
    dynamic responseData,
  ) {
    final frameStats = _getFrameStats(responseData);

    return [
      MapEntry('Frame totali', _stringValue(frameStats['total_frames'])),
      MapEntry('Frame attivi', _stringValue(frameStats['active_frames'])),
      MapEntry('Frame inattivi', _stringValue(frameStats['inactive_frames'])),
      MapEntry(
        'Frame attivi %',
        _formatPercent(frameStats['active_frames_percent']),
      ),
    ];
  }

  static List<MapEntry<String, String>> buildQualityRows(
    dynamic responseData,
  ) {
    final quality = _getQuality(responseData);
    final reasons = quality['reasons'];

    return [
      MapEntry(
        'Confidence score',
        _stringValue(quality['confidence_score']),
      ),
      MapEntry(
        'Confidence label',
        _stringValue(quality['confidence_label']),
      ),
      MapEntry(
        'Motivazioni',
        reasons is List ? reasons.join('\n') : 'Non disponibile',
      ),
    ];
  }

  static dynamic _getFrequencyAnalysis(dynamic responseData) {
    if (responseData is Map && responseData['frequency_analysis'] is Map) {
      return responseData['frequency_analysis'];
    }

    return {};
  }

  static dynamic _getOverall(dynamic responseData) {
    final frequencyAnalysis = _getFrequencyAnalysis(responseData);

    if (frequencyAnalysis is Map && frequencyAnalysis['overall'] is Map) {
      return frequencyAnalysis['overall'];
    }

    return {};
  }

  static dynamic _getQuality(dynamic responseData) {
    final frequencyAnalysis = _getFrequencyAnalysis(responseData);

    if (frequencyAnalysis is Map && frequencyAnalysis['quality'] is Map) {
      return frequencyAnalysis['quality'];
    }

    return {};
  }

  static dynamic _getFrameStats(dynamic responseData) {
    final frequencyAnalysis = _getFrequencyAnalysis(responseData);

    if (frequencyAnalysis is Map && frequencyAnalysis['frame_stats'] is Map) {
      return frequencyAnalysis['frame_stats'];
    }

    return {};
  }

  static String _formatRange(dynamic value) {
    if (value is List && value.length == 2) {
      return '${value[0]}-${value[1]} Hz';
    }

    return 'Non disponibile';
  }

  static String _formatPercent(dynamic value) {
    if (value == null) {
      return 'Non disponibile';
    }

    return '$value%';
  }

  static String _formatDb(dynamic value) {
    if (value == null) {
      return 'Non disponibile';
    }

    return '$value dB';
  }

  static String _formatStatus(dynamic value) {
    switch (value?.toString()) {
      case 'high':
        return 'Alto';
      case 'low':
        return 'Basso';
      case 'normal':
        return 'Normale';
      default:
        return 'Non disponibile';
    }
  }

  static String _stringValue(dynamic value, {String fallback = 'Non disponibile'}) {
    if (value == null) {
      return fallback;
    }

    return value.toString();
  }

  static double _doubleValue(dynamic value) {
    if (value == null) {
      return 0;
    }

    return double.tryParse(value.toString()) ?? 0;
  }
}

class TonalBandRow {
  final String key;
  final String label;
  final String range;
  final double energyPercent;
  final String energyText;
  final String status;
  final String avgDb;
  final String p10Db;
  final String p50Db;
  final String p90Db;
  final String peakDb;
  final String variationDb;

  const TonalBandRow({
    required this.key,
    required this.label,
    required this.range,
    required this.energyPercent,
    required this.energyText,
    required this.status,
    required this.avgDb,
    required this.p10Db,
    required this.p50Db,
    required this.p90Db,
    required this.peakDb,
    required this.variationDb,
  });

  factory TonalBandRow.empty(String key) {
    return TonalBandRow(
      key: key,
      label: key,
      range: 'Non disponibile',
      energyPercent: 0,
      energyText: 'Non disponibile',
      status: 'Non disponibile',
      avgDb: 'Non disponibile',
      p10Db: 'Non disponibile',
      p50Db: 'Non disponibile',
      p90Db: 'Non disponibile',
      peakDb: 'Non disponibile',
      variationDb: 'Non disponibile',
    );
  }
}