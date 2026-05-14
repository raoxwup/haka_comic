import 'package:flutter_test/flutter_test.dart';
import 'package:haka_comic/network/models.dart';

void main() {
  test('parses extra recommendation comic id response', () {
    final response = ExtraRecommendComicIdsResponse.fromJson({
      'code': 1,
      'recommendations': [
        '5f6226635e0ba7072ec37f45',
        '69e3c8176cd7082bd3f15eeb',
        '69fe12f83cf523631b9142ba',
        '69ff52623cf523631b914db5',
        '69fe126e6222ec619a2c439d',
        '69fe139cfeecda633bd63bc0',
        '69ff52d2d6b9fe65b3bf5f29',
        '69f4eaca65d95803a0836bea',
        '5c8fc916459fef312807decb',
        '69ecf56cbe8a111610caf973',
      ],
      'count': 10,
    });

    expect(response.code, 1);
    expect(response.count, 10);
    expect(response.recommendations, hasLength(10));
    expect(response.recommendations.first, '5f6226635e0ba7072ec37f45');
    expect(response.recommendations.last, '69ecf56cbe8a111610caf973');
  });
}
