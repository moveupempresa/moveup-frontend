import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// A selectable country: a stable id (from the underlying dataset) paired
/// with its Spanish display name, since the bundled dataset only ships
/// English names (e.g. "Spain" instead of "España").
class CountryOption {
  final int id;
  final String nameEs;

  const CountryOption(this.id, this.nameEs);
}

/// Loads country/city data from the `country_state_city_picker` package's
/// bundled asset and exposes it as a flat Country -> City list (skipping
/// the dataset's intermediate State/Province level, which the event form
/// has no use for).
class CountryCityData {
  CountryCityData._();

  static List<dynamic>? _raw;
  static List<CountryOption>? _countries;
  static final Map<int, List<String>> _citiesCache = {};

  static Future<void> _ensureLoaded() async {
    if (_raw != null) return;
    final jsonStr = await rootBundle.loadString(
      'packages/country_state_city_picker/lib/assets/country.json',
    );
    _raw = jsonDecode(jsonStr) as List<dynamic>;
  }

  static Future<List<CountryOption>> countries() async {
    if (_countries != null) return _countries!;
    await _ensureLoaded();
    final options = <CountryOption>[];
    for (final country in _raw!) {
      final id = country['id'] as int;
      final nameEs = _namesEs[id];
      if (nameEs == null) continue;
      options.add(CountryOption(id, nameEs));
    }
    options.sort((a, b) => a.nameEs.compareTo(b.nameEs));
    _countries = options;
    return options;
  }

  /// Cities for a country, aggregated across all of its states/provinces
  /// and deduplicated, since the form only asks for a city - not a region.
  static Future<List<String>> citiesForCountry(int countryId) async {
    final cached = _citiesCache[countryId];
    if (cached != null) return cached;
    await _ensureLoaded();
    final country = _raw!.firstWhere(
      (c) => c['id'] == countryId,
      orElse: () => null,
    );
    final cities = <String>{};
    if (country != null) {
      for (final state in (country['state'] as List<dynamic>? ?? [])) {
        for (final city in (state['city'] as List<dynamic>? ?? [])) {
          final name = city['name'] as String?;
          if (name != null && name.isNotEmpty) cities.add(name);
        }
      }
    }
    final sorted = cities.toList()..sort();
    _citiesCache[countryId] = sorted;
    return sorted;
  }

  // Spanish names, keyed by the dataset's stable numeric country id (the
  // dataset itself only ships English names).
  static const Map<int, String> _namesEs = {
    1: 'Afganistán',
    2: 'Islas Åland',
    3: 'Albania',
    4: 'Argelia',
    5: 'Samoa Americana',
    6: 'Andorra',
    7: 'Angola',
    8: 'Anguila',
    9: 'Antártida',
    10: 'Antigua y Barbuda',
    11: 'Argentina',
    12: 'Armenia',
    13: 'Aruba',
    14: 'Australia',
    15: 'Austria',
    16: 'Azerbaiyán',
    17: 'Bahamas',
    18: 'Baréin',
    19: 'Bangladés',
    20: 'Barbados',
    21: 'Bielorrusia',
    22: 'Bélgica',
    23: 'Belice',
    24: 'Benín',
    25: 'Bermudas',
    26: 'Bután',
    27: 'Bolivia',
    28: 'Bosnia y Herzegovina',
    29: 'Botsuana',
    30: 'Isla Bouvet',
    31: 'Brasil',
    32: 'Territorio Británico del Océano Índico',
    33: 'Brunéi',
    34: 'Bulgaria',
    35: 'Burkina Faso',
    36: 'Burundi',
    37: 'Camboya',
    38: 'Camerún',
    39: 'Canadá',
    40: 'Cabo Verde',
    41: 'Islas Caimán',
    42: 'República Centroafricana',
    43: 'Chad',
    44: 'Chile',
    45: 'China',
    46: 'Isla de Navidad',
    47: 'Islas Cocos (Keeling)',
    48: 'Colombia',
    49: 'Comoras',
    50: 'Congo',
    51: 'República Democrática del Congo',
    52: 'Islas Cook',
    53: 'Costa Rica',
    54: 'Costa de Marfil',
    55: 'Croacia',
    56: 'Cuba',
    57: 'Chipre',
    58: 'República Checa',
    59: 'Dinamarca',
    60: 'Yibuti',
    61: 'Dominica',
    62: 'República Dominicana',
    63: 'Timor Oriental',
    64: 'Ecuador',
    65: 'Egipto',
    66: 'El Salvador',
    67: 'Guinea Ecuatorial',
    68: 'Eritrea',
    69: 'Estonia',
    70: 'Etiopía',
    71: 'Islas Malvinas',
    72: 'Islas Feroe',
    73: 'Fiyi',
    74: 'Finlandia',
    75: 'Francia',
    76: 'Guayana Francesa',
    77: 'Polinesia Francesa',
    78: 'Tierras Australes y Antárticas Francesas',
    79: 'Gabón',
    80: 'Gambia',
    81: 'Georgia',
    82: 'Alemania',
    83: 'Ghana',
    84: 'Gibraltar',
    85: 'Grecia',
    86: 'Groenlandia',
    87: 'Granada',
    88: 'Guadalupe',
    89: 'Guam',
    90: 'Guatemala',
    91: 'Guernsey y Alderney',
    92: 'Guinea',
    93: 'Guinea-Bisáu',
    94: 'Guyana',
    95: 'Haití',
    96: 'Islas Heard y McDonald',
    97: 'Honduras',
    98: 'Hong Kong',
    99: 'Hungría',
    100: 'Islandia',
    101: 'India',
    102: 'Indonesia',
    103: 'Irán',
    104: 'Irak',
    105: 'Irlanda',
    106: 'Israel',
    107: 'Italia',
    108: 'Jamaica',
    109: 'Japón',
    110: 'Jersey',
    111: 'Jordania',
    112: 'Kazajistán',
    113: 'Kenia',
    114: 'Kiribati',
    115: 'Corea del Norte',
    116: 'Corea del Sur',
    117: 'Kuwait',
    118: 'Kirguistán',
    119: 'Laos',
    120: 'Letonia',
    121: 'Líbano',
    122: 'Lesoto',
    123: 'Liberia',
    124: 'Libia',
    125: 'Liechtenstein',
    126: 'Lituania',
    127: 'Luxemburgo',
    128: 'Macao',
    129: 'Macedonia del Norte',
    130: 'Madagascar',
    131: 'Malaui',
    132: 'Malasia',
    133: 'Maldivas',
    134: 'Mali',
    135: 'Malta',
    136: 'Isla de Man',
    137: 'Islas Marshall',
    138: 'Martinica',
    139: 'Mauritania',
    140: 'Mauricio',
    141: 'Mayotte',
    142: 'México',
    143: 'Micronesia',
    144: 'Moldavia',
    145: 'Mónaco',
    146: 'Mongolia',
    147: 'Montenegro',
    148: 'Montserrat',
    149: 'Marruecos',
    150: 'Mozambique',
    151: 'Myanmar',
    152: 'Namibia',
    153: 'Nauru',
    154: 'Nepal',
    155: 'Bonaire, San Eustaquio y Saba',
    156: 'Países Bajos',
    157: 'Nueva Caledonia',
    158: 'Nueva Zelanda',
    159: 'Nicaragua',
    160: 'Níger',
    161: 'Nigeria',
    162: 'Niue',
    163: 'Isla Norfolk',
    164: 'Islas Marianas del Norte',
    165: 'Noruega',
    166: 'Omán',
    167: 'Pakistán',
    168: 'Palaos',
    169: 'Palestina',
    170: 'Panamá',
    171: 'Papúa Nueva Guinea',
    172: 'Paraguay',
    173: 'Perú',
    174: 'Filipinas',
    175: 'Islas Pitcairn',
    176: 'Polonia',
    177: 'Portugal',
    178: 'Puerto Rico',
    179: 'Catar',
    180: 'Reunión',
    181: 'Rumanía',
    182: 'Rusia',
    183: 'Ruanda',
    184: 'Santa Elena',
    185: 'San Cristóbal y Nieves',
    186: 'Santa Lucía',
    187: 'San Pedro y Miquelón',
    188: 'San Vicente y las Granadinas',
    189: 'San Bartolomé',
    190: 'San Martín (parte francesa)',
    191: 'Samoa',
    192: 'San Marino',
    193: 'Santo Tomé y Príncipe',
    194: 'Arabia Saudita',
    195: 'Senegal',
    196: 'Serbia',
    197: 'Seychelles',
    198: 'Sierra Leona',
    199: 'Singapur',
    200: 'Eslovaquia',
    201: 'Eslovenia',
    202: 'Islas Salomón',
    203: 'Somalia',
    204: 'Sudáfrica',
    205: 'Islas Georgias del Sur',
    206: 'Sudán del Sur',
    207: 'España',
    208: 'Sri Lanka',
    209: 'Sudán',
    210: 'Surinam',
    211: 'Svalbard y Jan Mayen',
    212: 'Suazilandia',
    213: 'Suecia',
    214: 'Suiza',
    215: 'Siria',
    216: 'Taiwán',
    217: 'Tayikistán',
    218: 'Tanzania',
    219: 'Tailandia',
    220: 'Togo',
    221: 'Tokelau',
    222: 'Tonga',
    223: 'Trinidad y Tobago',
    224: 'Túnez',
    225: 'Turquía',
    226: 'Turkmenistán',
    227: 'Islas Turcas y Caicos',
    228: 'Tuvalu',
    229: 'Uganda',
    230: 'Ucrania',
    231: 'Emiratos Árabes Unidos',
    232: 'Reino Unido',
    233: 'Estados Unidos',
    234: 'Islas Ultramarinas Menores de Estados Unidos',
    235: 'Uruguay',
    236: 'Uzbekistán',
    237: 'Vanuatu',
    238: 'Ciudad del Vaticano',
    239: 'Venezuela',
    240: 'Vietnam',
    241: 'Islas Vírgenes Británicas',
    242: 'Islas Vírgenes de los Estados Unidos',
    243: 'Wallis y Futuna',
    244: 'Sahara Occidental',
    245: 'Yemen',
    246: 'Zambia',
    247: 'Zimbabue',
    248: 'Kosovo',
    249: 'Curazao',
    250: 'San Martín (parte neerlandesa)',
  };
}
