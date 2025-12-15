// import 'package:freezed_annotation/freezed_annotation.dart';

// part 'request_state.freezed.dart';

// @freezed
// abstract class RequestState<T> with _$RequestState<T> {
//   const RequestState._();

//   const factory RequestState.initial() = RequestInitial;

//   const factory RequestState.loading() = RequestLoading;

//   const factory RequestState.success(T data) = RequestSuccess;

//   const factory RequestState.error(Object error) = RequestError;

//   bool get loading => maybeWhen(loading: () => true, orElse: () => false);

//   bool get idle => maybeWhen(initial: () => true, orElse: () => false);

//   T? get data => whenOrNull(success: (v) => v);

//   Object? get error => whenOrNull(error: (e) => e);

//   bool get hasData => data != null;

//   bool get hasError => error != null;

//   bool get isLoadingOrInitial => loading || idle;
// }

sealed class RequestState<T> {
  const RequestState();

  bool get loading => this is Loading;

  bool get idle => this is Initial;

  bool get shouldLoading => loading || idle;

  T? get data => this is Success<T> ? (this as Success<T>).data : null;

  Object? get error => this is Error ? (this as Error).error : null;

  bool get hasData => data != null;

  bool get hasError => error != null;
}

final class Initial<T> extends RequestState<T> {
  const Initial();
}

final class Loading<T> extends RequestState<T> {
  const Loading();
}

final class Success<T> extends RequestState<T> {
  const Success(this.data);
  @override
  final T data;
}

final class Error<T> extends RequestState<T> {
  const Error(this.error);
  @override
  final Object error;
}
