class ReviewModel {
  final int id;
  final int productId;
  final int customerId;
  final int orderId;
  final int rating; // 1-5
  final String? comment;
  final List<String> images;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Populated field
  final CustomerInfo? customer;

  ReviewModel({
    required this.id,
    required this.productId,
    required this.customerId,
    required this.orderId,
    required this.rating,
    this.comment,
    required this.images,
    required this.createdAt,
    required this.updatedAt,
    this.customer,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] ?? 0,
      productId: json['product_id'] ?? 0,
      customerId: json['customer_id'] ?? 0,
      orderId: json['order_id'] ?? 0,
      rating: json['rating'] ?? 5,
      comment: json['comment'],
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      customer: json['customer'] != null
          ? CustomerInfo.fromJson(json['customer'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'customer_id': customerId,
      'order_id': orderId,
      'rating': rating,
      'comment': comment,
      'images': images,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'customer': customer?.toJson(),
    };
  }
}

class CustomerInfo {
  final int id;
  final String fullName;
  final String? avatar;

  CustomerInfo({required this.id, required this.fullName, this.avatar});

  factory CustomerInfo.fromJson(Map<String, dynamic> json) {
    return CustomerInfo(
      id: json['id'] ?? 0,
      fullName: json['full_name'] ?? 'Anonymous',
      avatar: json['avatar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'full_name': fullName, 'avatar': avatar};
  }
}

class RatingStatsModel {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution; // {5: 100, 4: 50, 3: 20, 2: 5, 1: 2}

  RatingStatsModel({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
  });

  factory RatingStatsModel.fromJson(Map<String, dynamic> json) {
    Map<int, int> distribution = {};
    if (json['rating_distribution'] != null) {
      final distJson = json['rating_distribution'] as Map<String, dynamic>;
      distJson.forEach((key, value) {
        distribution[int.parse(key)] = value as int;
      });
    }

    return RatingStatsModel(
      averageRating: (json['average_rating'] ?? 0.0).toDouble(),
      totalReviews: json['total_reviews'] ?? 0,
      ratingDistribution: distribution,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'average_rating': averageRating,
      'total_reviews': totalReviews,
      'rating_distribution': ratingDistribution.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
    };
  }

  int getRatingCount(int rating) => ratingDistribution[rating] ?? 0;

  double getRatingPercentage(int rating) {
    if (totalReviews == 0) return 0.0;
    return (getRatingCount(rating) / totalReviews) * 100;
  }
}
