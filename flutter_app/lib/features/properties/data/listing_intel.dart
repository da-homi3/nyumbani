/// Lightweight listing intel derived from amenities (mirrors web getListingIntel cues).
class ListingIntel {
  const ListingIntel({
    required this.water,
    required this.security,
    required this.internet,
    required this.parking,
  });

  final String water;
  final String security;
  final String internet;
  final bool parking;

  static ListingIntel fromAmenities(List<String> amenities) {
    final lower = amenities.map((a) => a.toLowerCase().replaceAll('_', ' ')).toList();
    bool has(String needle) => lower.any((a) => a.contains(needle));

    String water;
    if (has('borehole') || has('water tank') || has('reliable water')) {
      water = 'Excellent';
    } else if (has('water')) {
      water = 'Good';
    } else {
      water = 'Unknown';
    }

    String security;
    if (has('cctv') || has('gated') || has('security')) {
      security = 'Good';
    } else if (has('guard')) {
      security = 'Moderate';
    } else {
      security = 'Unknown';
    }

    String internet;
    if (has('fibre') || has('fiber') || has('wifi') || has('internet')) {
      internet = 'Yes';
    } else {
      internet = 'No fibre';
    }

    final parking = has('parking') || has('garage');

    return ListingIntel(
      water: water,
      security: security,
      internet: internet,
      parking: parking,
    );
  }

  static ColorTone toneFor(String label) {
    if (label == 'Excellent' || label == 'Good' || label == 'Yes') {
      return ColorTone.good;
    }
    if (label == 'Moderate') return ColorTone.mid;
    if (label == 'Unknown' || label == 'No fibre') return ColorTone.muted;
    return ColorTone.bad;
  }
}

enum ColorTone { good, mid, bad, muted }
