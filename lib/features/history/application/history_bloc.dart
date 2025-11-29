import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/history_database.dart';
import '../data/scan_record_model.dart';

part 'history_event.dart';
part 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final HistoryDatabase _db = HistoryDatabase.instance;

  HistoryBloc() : super(HistoryState.initial()) {
    on<LoadHistory>((event, emit) async {
      emit(HistoryState(status: HistoryStatus.loading, records: state.records));
      try {
        final records = await _db.readAllHistory();
        emit(HistoryState(status: HistoryStatus.loaded, records: records));
      } catch (e) {
        emit(HistoryState(status: HistoryStatus.error, records: []));
      }
    });

    on<AddHistoryRecord>((event, emit) async {
      await _db.create(event.record);
      add(LoadHistory());
    });

    on<DeleteHistoryRecord>((event, emit) async {
      await _db.delete(event.id);
      add(LoadHistory());
    });

    on<ClearAllHistory>((event, emit) async {
      await _db.clearAll();
      add(LoadHistory());
    });
  }
}
