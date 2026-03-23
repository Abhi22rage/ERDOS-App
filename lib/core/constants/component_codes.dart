class ComponentCodes {
  static const Map<String, String> categoryCodes = {
    'Machinery Components': 'MC',
    'Mechanical Components': 'MEC',
    'Electrical Components': 'EC',
    'Chemical & Treatment Components': 'CTC',
    'Consumables & Maintenance Materials': 'CMM',
    'Civil Components': 'CC',
  };

  static const Map<String, String> locationCodes = {
    'Panbazar Barge': 'PB',
    'Treatment Plant': 'WTP',
    'River Brahmaputra': 'RB',
    'Electrical Panel': 'EP',
    'Transformer': 'TR',
    'Transformer Control Pannel': 'TCP',
    'Plant & Barge': 'PBG',
    'Electrical system': 'ES',
    'Pumps & valves': 'PV',
    'Valves': 'VLV',
    'Pipe joints': 'PJ',
    'Maintenance work': 'MW',
    'Pipe & tank': 'PT',
    'Barge': 'BG',
    'Treatment plant': 'WTP',
  };

  static const Map<String, String> nameCodes = {
    'Pumpset': 'PMP',
    'Vacuum Pumpset': 'VPMP',
    'Back Washer Pumpset': 'BWP',
    'Air Blower': 'AB',
    'OHR Pumpset': 'OHRP',
    'Clarifier Scraper Pumpset': 'CSP',
    'DG Set': 'DG',
    'Transformer': 'TRF',
    'Barge Mechanical Structure': 'BMS',
    'Screening Filter': 'SF',
    'Flexible Hose Pipe': 'FHP',
    'Steel Ropes': 'SR',
    'Fullway Valve': 'FV',
    'Sluice Valve': 'SV',
    'NRVs (Non-return valves)': 'NRV',
    'Scraper Systems': 'SCR',
    'Spindle': 'SPD',
    'Air Valve': 'AV',
    'GI Nipple': 'GIN',
    'GI Union Socket': 'GUS',
    'Pipes': 'PP',
    'MCCB': 'MCCB',
    'MCB': 'MCB',
    'Capacitor': 'CAP',
    'Fuse Wire': 'FW',
    'Barrel': 'BRL',
    'Switch': 'SW',
    'LED Bulb': 'LED',
    'Tube Light': 'TL',
    'Bulb Holder': 'BH',
    'Electrical Tape': 'ET',
    'Alum': 'ALM',
    'Hydrated Lime': 'HL',
    'Bleaching Powder': 'BP',
    'Gland Packing': 'GP',
    'Nut & Bolt': 'NB',
    'Rubber Gasket': 'RG',
    'Grease': 'GRS',
    'Cotton Waste': 'CW',
    'Handwash': 'HW',
    'Teflon Tape': 'TT',
    'Hacksaw Blade': 'HB',
    'UPVC Solvent': 'US',
    'M-Seal': 'MS',
    'Coconut Rope': 'CR',
    'Filter Sand': 'FS',
    'Aerator (2 Nos)': 'AER',
    'Mixer': 'MIX',
    'Lime Doser': 'LD',
    'Alum Doser': 'AD',
    'Tube Shettler': 'TS',
    'Floculator': 'FLC',
    'Clarifier Unit': 'CU',
    'Sludge Pit': 'SP',
    'Rapid Sand Filter (2 Nos)': 'RSF',
    'Chlorinator': 'CHL',
    'Water Reserviour': 'RES',
  };

  static String getCategoryCode(String? category) {
    if (category == null) return 'XX';
    return categoryCodes[category] ?? category.substring(0, 2).toUpperCase();
  }

  static String getLocationCode(String? location) {
    if (location == null) return 'LOC';
    return locationCodes[location] ?? (location.length >= 3 ? location.substring(0, 3).toUpperCase() : location.toUpperCase());
  }

  static String getNameCode(String? name) {
    if (name == null) return 'CMP';
    return nameCodes[name] ?? (name.length >= 3 ? name.substring(0, 3).toUpperCase() : name.toUpperCase());
  }

  /// Generates a structured Incident ID based on codes
  static String generateIncidentId({
    required String? scheme,
    required String? category,
    required String? type,
    required String? unit,
  }) {
    String s = scheme != null && scheme.contains(' ') ? scheme.split(' ').map((e) => e[0]).join() : 'SCH';
    String c = getCategoryCode(category);
    // Remove "Unit" word if present in unit string to keep it short
    String u = unit != null ? unit.replaceAll(RegExp(r'[^0-9]'), '') : '00';
    if (u.isEmpty) u = '01';
    
    // Use part of timestamp for uniqueness
    String ts = DateTime.now().millisecondsSinceEpoch.toString().substring(10);
    
    return '${s}-${c}-${u}-${ts}';
  }
}
