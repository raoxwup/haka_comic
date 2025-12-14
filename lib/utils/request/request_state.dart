import 'package:freezed_annotation/freezed_annotation.dart';

part 'request_state.freezed.dart';

@freezed
abstract class RequestState<T> with _$RequestState<T> {
  const RequestState._();

  const factory RequestState.initial() = RequestInitial;

  const factory RequestState.loading() = RequestLoading;

  const factory RequestState.success(T data) = RequestSuccess;

  const factory RequestState.error(Object error) = RequestError;

  bool get loading => maybeWhen(loading: () => true, orElse: () => false);

  bool get idle => maybeWhen(initial: () => true, orElse: () => false);

  T? get data => whenOrNull(success: (v) => v);

  Object? get error => whenOrNull(error: (e) => e);

  bool get hasData => data != null;

  bool get hasError => error != null;

  bool get isLoadingOrInitial => loading || idle;
}
