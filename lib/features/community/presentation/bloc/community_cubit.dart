import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/community_models.dart';
import '../../data/repositories/community_repository.dart';

/// Cubit for the community feed (spaces + posts + interactions).
class CommunityCubit extends Cubit<CommunityState> {
  CommunityCubit(this._repository) : super(const CommunityLoading());

  final CommunityRepository _repository;
  String? _selectedSpaceId;

  String? get selectedSpaceId => _selectedSpaceId;

  Future<void> load() async {
    emit(const CommunityLoading());
    try {
      final spaces = await _repository.fetchSpaces();
      final posts = await _repository.fetchPosts(spaceId: _selectedSpaceId);
      emit(CommunityReady(spaces: spaces, posts: posts, selectedSpaceId: _selectedSpaceId));
    } catch (e) {
      emit(CommunityError(message: e.toString()));
    }
  }

  Future<void> selectSpace(String? spaceId) async {
    _selectedSpaceId = spaceId;
    final current = state is CommunityReady
        ? state as CommunityReady
        : const CommunityReady(spaces: [], posts: []);
    emit(current.copyWith(selectedSpaceId: spaceId));
    try {
      final posts = await _repository.fetchPosts(spaceId: spaceId);
      emit(CommunityReady(
        spaces: current.spaces,
        posts: posts,
        selectedSpaceId: spaceId,
      ));
    } catch (e) {
      emit(CommunityError(message: e.toString()));
    }
  }

  Future<void> createPost(String? spaceId, String body,
      {String? title, bool isAnonymous = false}) async {
    final targetSpace = spaceId ??
        _selectedSpaceId ??
        ((state is CommunityReady && (state as CommunityReady).spaces.isNotEmpty)
            ? (state as CommunityReady).spaces.first.id
            : null);
    if (targetSpace == null) return;
    await _repository.createPost(targetSpace, body,
        title: title, isAnonymous: isAnonymous);
    await load();
  }

  Future<void> toggleLike(String postId) async {
    final current = state is CommunityReady
        ? state as CommunityReady
        : const CommunityReady(spaces: [], posts: []);
    // optimistic update
    final updatedPosts = current.posts.map((p) {
      if (p.id != postId) return p;
      return PostModel(
        id: p.id,
        spaceId: p.spaceId,
        userId: p.userId,
        title: p.title,
        body: p.body,
        isAnonymous: p.isAnonymous,
        authorName: p.authorName,
        likeCount: p.likedByMe ? p.likeCount - 1 : p.likeCount + 1,
        likedByMe: !p.likedByMe,
        commentCount: p.commentCount,
        createdAt: p.createdAt,
      );
    }).toList();
    emit(CommunityReady(
      spaces: current.spaces,
      posts: updatedPosts,
      selectedSpaceId: _selectedSpaceId,
    ));
    try {
      await _repository.toggleLike(postId);
    } catch (_) {
      // revert silently by reloading
      await load();
    }
  }

  Future<void> createSpace(String name, String description) async {
    await _repository.createSpace(name, description);
    await load();
  }
}

/// Base state for [CommunityCubit].
abstract class CommunityState extends Equatable {
  const CommunityState();

  @override
  List<Object?> get props => const [];
}

class CommunityLoading extends CommunityState {
  const CommunityLoading();
}

class CommunityError extends CommunityState {
  const CommunityError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

class CommunityReady extends CommunityState {
  const CommunityReady({
    required this.spaces,
    required this.posts,
    this.selectedSpaceId,
  });

  final List<SpaceModel> spaces;
  final List<PostModel> posts;
  final String? selectedSpaceId;

  @override
  List<Object?> get props => [spaces, posts, selectedSpaceId];

  CommunityReady copyWith({String? selectedSpaceId}) => CommunityReady(
        spaces: spaces,
        posts: posts,
        selectedSpaceId: selectedSpaceId ?? this.selectedSpaceId,
      );
}
