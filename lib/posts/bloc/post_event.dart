part of 'post_bloc.dart';

sealed class PostEvent extends Equatable {
  @override
  // TODO: implement props
  List<Object?> get props => [];
}

final class MorePosts extends PostEvent {}
