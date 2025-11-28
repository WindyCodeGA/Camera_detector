part of 'history_bloc.dart';

enum HistoryStatus { initial, loading, loaded, error }

class HistoryState {
  final HistoryStatus status;
  final List<ScanRecord> records;

  HistoryState({required this.status, required this.records});

  factory HistoryState.initial() {
    return HistoryState(status: HistoryStatus.initial, records: []);
  }
}
