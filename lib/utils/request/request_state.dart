sealed class RequestState<T> {
  const RequestState();

  bool get loading => this is Loading;

  bool get idle => this is Initial;

  bool get shouldLoading => loading || idle;

  T? get data => switch (this) {
    Success(:final data) => data,
    Loading(:final data) => data,
    _ => null,
  };

  Object? get error => this is Error ? (this as Error).error : null;

  bool get hasData => data != null;

  bool get hasError => error != null;
}

final class Initial<T> extends RequestState<T> {
  const Initial();
}

final class Loading<T> extends RequestState<T> {
  const Loading(this.data);
  @override
  final T? data;
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
