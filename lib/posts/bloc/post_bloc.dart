import 'package:stream_transform/stream_transform.dart';
import 'package:equatable/equatable.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

// import 'package:flutter_infinite_list/bloc/bloc.dart';
import 'package:infinite_list/posts/model/post.dart';

part 'post_event.dart';
part 'post_state.dart';

class PostBloc extends Bloc<PostEvent, PostState> {
  final http.Client httpClient;

  PostBloc({required this.httpClient}) : super(const PostState()) {
    // TODO: register on<PostFetched> event
    on<MorePosts>(_onPostsFetched,
        transformer: throttleDroppable(const Duration(milliseconds: 200)));

    // TODO: what is `addError`?
  }

  void _onPostsFetched(MorePosts event, Emitter<PostState> emit) async {
    if (state.hasReachedMax) return;
    try {
      if (state.status == PostStatus.initial) {
        final posts = await _fetch();
        emit(state.copyWith(
            status: PostStatus.success, posts: posts, hasReachedMax: false));
        return;
      }
      final posts = await _fetch(state.posts.length);
      emit(posts.isEmpty
          ? state.copyWith(hasReachedMax: true)
          : state.copyWith(
              status: PostStatus.success,
              posts: [...state.posts, ...posts],
              hasReachedMax: false));
    } catch (e) {
      emit(state.copyWith(status: PostStatus.failure, error: e));
    }
  }

  Future<List<Post>> _fetch([int startIndex = 0]) async {
    if (startIndex == 30) throw 'You have reached your max limit';

    final response = await httpClient.get(
      Uri.https(
        'jsonplaceholder.typicode.com',
        '/posts',
        <String, String>{'_start': '$startIndex', '_limit': '10'},
      ),
    );
    if (response.statusCode == 200) {
      final body = json.decode(response.body) as List;
      return body.map((dynamic json) {
        final map = json as Map<String, dynamic>;
        return Post(
          id: map['id'] as int,
          title: map['title'] as String,
          body: map['body'] as String,
        );
      }).toList();
    }
    throw Exception('error fetching posts');
  }
}

EventTransformer<E> throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}
