part of 'history_bloc.dart';

abstract class HistoryEvent {}

class LoadHistory extends HistoryEvent {}

class AddHistoryRecord extends HistoryEvent {
  final ScanRecord record;
  AddHistoryRecord(this.record);
}

class DeleteHistoryRecord extends HistoryEvent {
  final int id;
  DeleteHistoryRecord(this.id);
}

class ClearAllHistory extends HistoryEvent {}
