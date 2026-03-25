enum PostType { image, video, news }

class Post {
  final String postId;    // DAGDAGAN ITO
  final String userId;
  final String username;
  final String handle;
  final String profileUrl;
  final String content;
  final String? mediaUrl;
  final PostType type;
  final String likes;     // String ito sa dummy data mo
  final String comments;
  final String? newsTitle;
  final String? newsSubtext;

  Post({
    required this.postId, // DAGDAGAN ITO
    required this.userId,
    required this.username,
    required this.handle,
    required this.profileUrl,
    required this.content,
    this.mediaUrl,
    required this.type,
    required this.likes,
    required this.comments,
    this.newsTitle,
    this.newsSubtext,
  });
}