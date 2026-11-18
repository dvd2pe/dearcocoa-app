import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/supabase_client.dart';
import '../models/community_models.dart';

/// Cloud repository for DearCocoa community spaces.
class CommunityRepository {
  SupabaseClient get _client {
    final client = supabase;
    if (client == null) {
      throw StateError('Supabase not configured');
    }
    return client;
  }

  /// All community spaces.
  Future<List<SpaceModel>> fetchSpaces() async {
    final rows = await _client
        .from('spaces')
        .select()
        .order('created_at', ascending: true);
    final list = rows as List<dynamic>;
    return list
        .map((e) => SpaceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Feed of posts, optionally filtered by space. Enriched with likes,
  /// comments and author profile (viewing user resolved for likedByMe).
  Future<List<PostModel>> fetchPosts({String? spaceId}) async {
    final viewerId = currentUserId;
    var query = _client
        .from('posts')
        .select('*, profiles(display_name), post_likes(user_id), comments(post_id)');
    if (spaceId != null) {
      query = query.eq('space_id', spaceId);
    }
    final rows = await query.order('created_at', ascending: false).limit(50);
    final list = rows as List<dynamic>;
    return list
        .map((e) => PostModel.fromJson(
              e as Map<String, dynamic>,
              viewerId: viewerId,
            ))
        .toList();
  }

  /// Creates a post in a space.
  Future<void> createPost(
    String spaceId,
    String body, {
    String? title,
    bool isAnonymous = false,
  }) async {
    await _client.from('posts').insert({
      'space_id': spaceId,
      'user_id': currentUserId,
      'body': body,
      if (title != null && title.isNotEmpty) 'title': title,
      'is_anonymous': isAnonymous,
    });
  }

  /// Toggles the viewer's like on a post. Returns true when now liked.
  Future<bool> toggleLike(String postId) async {
    final viewerId = currentUserId!;
    final existing = await _client
        .from('post_likes')
        .select('post_id')
        .eq('post_id', postId)
        .eq('user_id', viewerId)
        .limit(1);
    if ((existing as List<dynamic>).isNotEmpty) {
      await _client
          .from('post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', viewerId);
      return false;
    }
    await _client
        .from('post_likes')
        .insert({'post_id': postId, 'user_id': viewerId});
    return true;
  }

  /// Comments of a post (oldest first).
  Future<List<CommentModel>> fetchComments(String postId) async {
    final rows = await _client
        .from('comments')
        .select('*, profiles(display_name)')
        .eq('post_id', postId)
        .order('created_at', ascending: true)
        .limit(100);
    final list = rows as List<dynamic>;
    return list
        .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Adds a comment.
  Future<void> addComment(String postId, String body) async {
    await _client.from('comments').insert({
      'post_id': postId,
      'user_id': currentUserId,
      'body': body,
    });
  }

  /// Creates a new community space (creator becomes admin member).
  Future<void> createSpace(String name, String description) async {
    final slug = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final res = await _client
        .from('spaces')
        .insert({
          'name': name,
          'slug': slug.isEmpty
              ? 'space-${DateTime.now().millisecondsSinceEpoch}'
              : slug,
          'description': description,
          'created_by': currentUserId,
        })
        .select('id')
        .single();
    await _client.from('space_members').insert({
      'space_id': res['id'] as String,
      'user_id': currentUserId,
      'role': 'admin',
    });
  }

  /// Joins a space (member).
  Future<void> joinSpace(String spaceId) async {
    await _client.from('space_members').insert({
      'space_id': spaceId,
      'user_id': currentUserId,
      'role': 'member',
    });
  }
}
