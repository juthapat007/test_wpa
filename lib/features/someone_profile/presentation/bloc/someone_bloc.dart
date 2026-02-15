import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'someone_event.dart';
part 'someone_state.dart';

class SomeoneBloc extends Bloc<SomeoneEvent, SomeoneState> {
  SomeoneBloc() : super(SomeoneInitial()) {
    on<SomeoneEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
