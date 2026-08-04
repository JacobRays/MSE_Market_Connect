import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mse_market_connect/shared/models/news_model.dart';

class NewsService {
  final _db = Supabase.instance.client;

  Future<List<NewsModel>> getLatestNews() async {
    final response = await _db
        .from('news')
        .select()
        .order('published_at', ascending: false)
        .limit(20);

    return (response as List).map((e) => NewsModel.fromMap(e)).toList();
  }
}
