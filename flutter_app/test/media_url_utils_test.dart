import 'package:flutter_test/flutter_test.dart';

import 'package:nyumbasearch/features/properties/presentation/media_url_utils.dart';

void main() {
  group('media_url_utils', () {
    test('youtubeEmbedUrl extracts watch URL id', () {
      expect(
        youtubeEmbedUrl('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
        'https://www.youtube.com/embed/dQw4w9WgXcQ?rel=0&modestbranding=1&playsinline=1&hd=1',
      );
    });

    test('youtubeEmbedUrl extracts youtu.be id', () {
      expect(
        youtubeEmbedUrl('https://youtu.be/abc123'),
        contains('abc123'),
      );
    });

    test('isLikelyDirectVideoUrl detects mp4', () {
      expect(isLikelyDirectVideoUrl('https://cdn.example.com/walk.mp4'), isTrue);
      expect(
        isLikelyDirectVideoUrl('https://www.youtube.com/watch?v=abc'),
        isFalse,
      );
    });

    test('matterportEmbedUrl normalizes tour link', () {
      expect(
        matterportEmbedUrl('https://my.matterport.com/show/?m=AbCdEf12'),
        'https://my.matterport.com/show/?m=AbCdEf12&play=1',
      );
    });
  });
}
