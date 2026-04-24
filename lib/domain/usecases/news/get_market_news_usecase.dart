import 'dart:async';

import '../../entities/news_entity.dart';

abstract class NewsRepository {
  Future<List<NewsEntity>> getMarketNews({int page, int pageSize});
}

class GetMarketNewsParams {
  late final int page;
  late final int pageSize;

  GetMarketNewsParams({this.page = 1, this.pageSize = 20});
}

class GetMarketNewsUseCase {
  final NewsRepository repository;

  GetMarketNewsUseCase(this.repository);

  Future<List<NewsEntity>> call(GetMarketNewsParams params) async {
    if (params.page < 1) params.page = 1;
    if (params.pageSize < 1 || params.pageSize > 100) params.pageSize = 20;
    return await repository.getMarketNews(
      page: params.page,
      pageSize: params.pageSize,
    );
  }
}
