import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../application/history_bloc.dart';
import '../../data/scan_record_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();

    context.read<HistoryBloc>().add(LoadHistory());
  }

  // Hàm helper ta dùng để chọn icon và màu dựa trên loại quét
  IconData _getIcon(ScanType type) {
    switch (type) {
      case ScanType.magnetic:
        return Icons.explore;
      case ScanType.infrared:
        return Icons.videocam;
      case ScanType.wifi:
        return Icons.wifi;
      case ScanType.bluetooth:
        return Icons.bluetooth;
    }
  }

  Color _getColor(ScanType type) {
    switch (type) {
      case ScanType.magnetic:
        return Colors.orange;
      case ScanType.infrared:
        return Colors.red;
      case ScanType.wifi:
        return Colors.blue;
      case ScanType.bluetooth:
        return Colors.indigo;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan History"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () {
              context.read<HistoryBloc>().add(ClearAllHistory());
            },
          ),
        ],
      ),
      body: BlocBuilder<HistoryBloc, HistoryState>(
        builder: (context, state) {
          if (state.status == HistoryStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.records.isEmpty) {
            return const Center(child: Text("There is no scan history yet."));
          }

          return ListView.builder(
            itemCount: state.records.length,
            itemBuilder: (context, index) {
              final record = state.records[index];
              return Dismissible(
                key: Key(record.id.toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  context.read<HistoryBloc>().add(
                    DeleteHistoryRecord(record.id!),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getColor(record.type).withAlpha(50),
                      child: Icon(
                        _getIcon(record.type),
                        color: _getColor(record.type),
                      ),
                    ),
                    title: Text(
                      record.value,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(record.timestamp),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
