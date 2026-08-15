/// Static imagery + fallback “from” prices — port of web `hood-meta.ts`.
class HoodMeta {
  const HoodMeta({required this.fromKes, required this.imageUrl});

  final int fromKes;
  final String imageUrl;
}

const kHoodMeta = <String, HoodMeta>{
  'Kilimani': HoodMeta(
    fromKes: 18000,
    imageUrl: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=400&q=80',
  ),
  'Westlands': HoodMeta(
    fromKes: 25000,
    imageUrl: 'https://images.unsplash.com/photo-1502672023488-70e25813eb80?w=400&q=80',
  ),
  'Karen': HoodMeta(
    fromKes: 50000,
    imageUrl: 'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=400&q=80',
  ),
  'Lavington': HoodMeta(
    fromKes: 45000,
    imageUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=400&q=80',
  ),
  'Kileleshwa': HoodMeta(
    fromKes: 35000,
    imageUrl: 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=400&q=80',
  ),
  'Kasarani': HoodMeta(
    fromKes: 12000,
    imageUrl: 'https://images.unsplash.com/photo-1493663284031-b7e3aefcae8e?w=400&q=80',
  ),
  'South B': HoodMeta(
    fromKes: 20000,
    imageUrl: 'https://images.unsplash.com/photo-1484154218962-a197022b5858?w=400&q=80',
  ),
  'South C': HoodMeta(
    fromKes: 18000,
    imageUrl: 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=400&q=80',
  ),
  'Roysambu': HoodMeta(
    fromKes: 8000,
    imageUrl: 'https://images.unsplash.com/photo-1555854877-bab0e564b8d5?w=400&q=80',
  ),
  'Rongai': HoodMeta(
    fromKes: 12000,
    imageUrl: 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=400&q=80',
  ),
  'Ruaka': HoodMeta(
    fromKes: 15000,
    imageUrl: 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=400&q=80',
  ),
  'Parklands': HoodMeta(
    fromKes: 28000,
    imageUrl: 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=400&q=80',
  ),
  'Ngong Road': HoodMeta(
    fromKes: 22000,
    imageUrl: 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=400&q=80',
  ),
};

const _kFallbackImgs = <String>[
  'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=400&q=80',
  'https://images.unsplash.com/photo-1502672023488-70e25813eb80?w=400&q=80',
  'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=400&q=80',
  'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=400&q=80',
  'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=400&q=80',
  'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=400&q=80',
];

int _hashName(String name) {
  var h = 0;
  for (final code in name.codeUnits) {
    h = (h * 31 + code) & 0x7fffffff;
  }
  return h;
}

HoodMeta resolveHoodMeta(String name) {
  final exact = kHoodMeta[name];
  if (exact != null) return exact;

  final lower = name.trim().toLowerCase();
  for (final entry in kHoodMeta.entries) {
    if (entry.key.toLowerCase() == lower) return entry.value;
  }
  for (final entry in kHoodMeta.entries) {
    final k = entry.key.toLowerCase();
    if (lower.contains(k) || k.contains(lower)) return entry.value;
  }

  return HoodMeta(
    fromKes: 15000,
    imageUrl: _kFallbackImgs[_hashName(lower) % _kFallbackImgs.length],
  );
}
