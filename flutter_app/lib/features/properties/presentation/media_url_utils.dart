// URL helpers for property walkthrough / 360 media (parity with website video-embed.ts).

bool isExternalVideoEmbed(String url) {
  return RegExp(r'youtube\.com|youtu\.be|vimeo\.com', caseSensitive: false)
      .hasMatch(url);
}

String? youtubeEmbedUrl(String url) {
  try {
    final u = Uri.parse(url);
    String id = '';
    final host = u.host.toLowerCase();
    if (host.contains('youtu.be')) {
      id = u.pathSegments.isNotEmpty ? u.pathSegments.first : '';
    } else if (u.path.startsWith('/embed/')) {
      id = u.pathSegments.length > 1 ? u.pathSegments[1] : '';
    } else if (u.path.startsWith('/shorts/')) {
      id = u.pathSegments.length > 1 ? u.pathSegments[1] : '';
    } else {
      id = u.queryParameters['v'] ?? '';
    }
    if (id.isEmpty) return null;
    return 'https://www.youtube.com/embed/$id?rel=0&modestbranding=1&playsinline=1&hd=1';
  } catch (_) {
    return null;
  }
}

String? vimeoEmbedUrl(String url) {
  try {
    final match = RegExp(r'/(?:video/)?(\d+)').firstMatch(Uri.parse(url).path);
    final id = match?.group(1);
    if (id == null) return null;
    return 'https://player.vimeo.com/video/$id';
  } catch (_) {
    return null;
  }
}

String? externalVideoEmbedUrl(String url) {
  if (RegExp(r'youtube\.com|youtu\.be', caseSensitive: false).hasMatch(url)) {
    return youtubeEmbedUrl(url);
  }
  if (RegExp(r'vimeo\.com', caseSensitive: false).hasMatch(url)) {
    return vimeoEmbedUrl(url);
  }
  return null;
}

bool isExternalTourEmbed(String url) {
  return RegExp(
    r'matterport\.com|my\.matterport|kuula\.co|roundme\.com|youtube\.com|youtu\.be|vimeo\.com',
    caseSensitive: false,
  ).hasMatch(url);
}

String matterportEmbedUrl(String url) {
  final match = RegExp(r'[?&]m=([A-Za-z0-9]+)').firstMatch(url) ??
      RegExp(r'show/\?m=([A-Za-z0-9]+)').firstMatch(url);
  final id = match?.group(1);
  if (id != null) return 'https://my.matterport.com/show/?m=$id&play=1';
  return url;
}

bool isLikelyImageUrl(String url) {
  final path = url.split('?').first.toLowerCase();
  return path.endsWith('.jpg') ||
      path.endsWith('.jpeg') ||
      path.endsWith('.png') ||
      path.endsWith('.webp') ||
      path.endsWith('.gif');
}

bool isLikelyDirectVideoUrl(String url) {
  if (isExternalVideoEmbed(url)) return false;
  final path = url.split('?').first.toLowerCase();
  if (path.endsWith('.mp4') ||
      path.endsWith('.m4v') ||
      path.endsWith('.webm') ||
      path.endsWith('.mov') ||
      path.endsWith('.m3u8')) {
    return true;
  }
  // Supabase / R2 property media without extension — try native player.
  return path.contains('/storage/') ||
      path.contains('/property-media') ||
      path.contains('/videos/');
}
