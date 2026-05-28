import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/review.dart';

class ReviewStorage {
  static const String _key = 'local_reviews';

  Future<List<Review>> loadReviews() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => Review.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<void> saveReview(Review review) async {
    final reviews = await loadReviews();
    reviews.insert(0, review);
    await _saveAll(reviews);
  }

  Future<void> _saveAll(List<Review> reviews) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(reviews.map((review) => review.toJson()).toList());
    await prefs.setString(_key, raw);
  }
}
