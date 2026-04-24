class CompanyInfoModel {
  final String symbol;
  final String name;
  final String exchange;
  final String currency;
  final String country;
  final String sector;
  final String industry;
  final String? description;
  final String? website;
  final double? marketCap;
  final double? peRatio;
  final double? eps;
  final double? dividendYield;
  final double? fiftyTwoWeekHigh;
  final double? fiftyTwoWeekLow;
  final String? logoUrl;

  const CompanyInfoModel({
    required this.symbol,
    required this.name,
    required this.exchange,
    required this.currency,
    required this.country,
    required this.sector,
    required this.industry,
    this.description,
    this.website,
    this.marketCap,
    this.peRatio,
    this.eps,
    this.dividendYield,
    this.fiftyTwoWeekHigh,
    this.fiftyTwoWeekLow,
    this.logoUrl,
  });

  factory CompanyInfoModel.fromMap(Map<String, dynamic> map) {
    return CompanyInfoModel(
      symbol: map['symbol']?.toString() ?? '',
      name: map['name']?.toString() ?? map['Name']?.toString() ?? '',
      exchange:
          map['exchange']?.toString() ?? map['Exchange']?.toString() ?? '',
      currency:
          map['currency']?.toString() ?? map['Currency']?.toString() ?? 'INR',
      country: map['country']?.toString() ?? map['Country']?.toString() ?? '',
      sector:
          map['sector']?.toString() ?? map['Sector']?.toString() ?? 'Unknown',
      industry: map['industry']?.toString() ??
          map['Industry']?.toString() ??
          'Unknown',
      description:
          map['description']?.toString() ?? map['Description']?.toString(),
      website: map['website']?.toString() ?? map['OfficialSite']?.toString(),
      marketCap: _toDouble(map['marketCap'] ?? map['MarketCapitalization']),
      peRatio: _toDouble(map['peRatio'] ?? map['PERatio']),
      eps: _toDouble(map['eps'] ?? map['EPS']),
      dividendYield: _toDouble(map['dividendYield'] ?? map['DividendYield']),
      fiftyTwoWeekHigh: _toDouble(map['52WeekHigh']),
      fiftyTwoWeekLow: _toDouble(map['52WeekLow']),
      logoUrl: map['logo_url']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'symbol': symbol,
        'name': name,
        'exchange': exchange,
        'currency': currency,
        'country': country,
        'sector': sector,
        'industry': industry,
        if (description != null) 'description': description,
        if (website != null) 'website': website,
        if (marketCap != null) 'marketCap': marketCap,
        if (peRatio != null) 'peRatio': peRatio,
        if (eps != null) 'eps': eps,
        if (dividendYield != null) 'dividendYield': dividendYield,
        if (fiftyTwoWeekHigh != null) '52WeekHigh': fiftyTwoWeekHigh,
        if (fiftyTwoWeekLow != null) '52WeekLow': fiftyTwoWeekLow,
        if (logoUrl != null) 'logo_url': logoUrl,
      };

  static double? _toDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  @override
  String toString() => 'CompanyInfoModel(symbol: $symbol, name: $name)';
}
