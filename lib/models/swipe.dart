enum SwipeDirection { left, right, up }

SwipeDirection swipeDirectionFromDb(String raw) {
  switch (raw) {
    case 'left':
      return SwipeDirection.left;
    case 'right':
      return SwipeDirection.right;
    case 'up':
      return SwipeDirection.up;
  }
  throw ArgumentError('Unknown swipe direction: $raw');
}

String swipeDirectionToDb(SwipeDirection d) {
  switch (d) {
    case SwipeDirection.left:
      return 'left';
    case SwipeDirection.right:
      return 'right';
    case SwipeDirection.up:
      return 'up';
  }
}

class Swipe {
  final String id;
  final String userId;
  final String shopId;
  final SwipeDirection direction;
  final DateTime createdAt;

  const Swipe({
    required this.id,
    required this.userId,
    required this.shopId,
    required this.direction,
    required this.createdAt,
  });

  factory Swipe.fromJson(Map<String, dynamic> json) {
    return Swipe(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      shopId: json['shop_id'] as String,
      direction: swipeDirectionFromDb(json['direction'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'shop_id': shopId,
        'direction': swipeDirectionToDb(direction),
        'created_at': createdAt.toIso8601String(),
      };
}
