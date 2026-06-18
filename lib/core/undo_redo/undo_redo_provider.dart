import 'package:carpe_diem/core/constants/app_constants.dart';
import 'package:carpe_diem/core/undo_redo/command.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum UndoRedoOperationType { execute, undo, redo, none }

class UndoRedoState {
  final bool canUndo;
  final bool canRedo;
  final String? undoDescription;
  final String? redoDescription;
  final bool isProcessing;
  final UndoRedoOperationType lastOperationType;
  final List<Command> undoStack;
  final List<Command> redoStack;

  const UndoRedoState({
    required this.canUndo,
    required this.canRedo,
    this.isProcessing = false,
    this.lastOperationType = UndoRedoOperationType.none,
    this.undoDescription,
    this.redoDescription,
    this.undoStack = const [],
    this.redoStack = const [],
  });

  UndoRedoState copyWith({
    bool? canUndo,
    bool? canRedo,
    bool? isProcessing,
    UndoRedoOperationType? lastOperationType,
    String? undoDescription,
    String? redoDescription,
    List<Command>? undoStack,
    List<Command>? redoStack,
  }) {
    return UndoRedoState(
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
      isProcessing: isProcessing ?? this.isProcessing,
      lastOperationType: lastOperationType ?? this.lastOperationType,
      undoDescription: undoDescription ?? this.undoDescription,
      redoDescription: redoDescription ?? this.redoDescription,
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
    );
  }
}

class UndoRedoNotifier extends Notifier<UndoRedoState> {
  final _undoStack = <Command>[];
  final _redoStack = <Command>[];

  @override
  UndoRedoState build() {
    return const UndoRedoState(canUndo: false, canRedo: false, undoStack: [], redoStack: []);
  }

  Future<void> execute(Command cmd) async {
    if (state.isProcessing) return;
    state = state.copyWith(isProcessing: true, lastOperationType: UndoRedoOperationType.execute);
    try {
      await cmd.execute();
      _undoStack.add(cmd);
      if (_undoStack.length > AppConstants.maxUndoRedoStackSize) {
        _undoStack.removeAt(0);
      }
      _redoStack.clear();
    } finally {
      _updateState(UndoRedoOperationType.execute);
    }
  }

  Future<void> undo() async {
    if (state.isProcessing || _undoStack.isEmpty) return;
    state = state.copyWith(isProcessing: true, lastOperationType: UndoRedoOperationType.undo);
    try {
      final cmd = _undoStack.removeLast();
      await cmd.undo();
      _redoStack.add(cmd);
    } finally {
      _updateState(UndoRedoOperationType.undo);
    }
  }

  Future<void> redo() async {
    if (state.isProcessing || _redoStack.isEmpty) return;
    state = state.copyWith(isProcessing: true, lastOperationType: UndoRedoOperationType.redo);
    try {
      final cmd = _redoStack.removeLast();
      await cmd.execute();
      _undoStack.add(cmd);
    } finally {
      _updateState(UndoRedoOperationType.redo);
    }
  }

  Future<void> jumpTo(Command targetCommand) async {
    if (state.isProcessing) return;

    final undoIndex = _undoStack.indexOf(targetCommand);
    if (undoIndex != -1) {
      // undo elements executed after the target to revert state to that point
      final undosCount = _undoStack.length - 1 - undoIndex;
      if (undosCount <= 0) return;

      state = state.copyWith(isProcessing: true, lastOperationType: UndoRedoOperationType.undo);
      try {
        for (int i = 0; i < undosCount; i++) {
          if (_undoStack.isEmpty) break;
          final cmd = _undoStack.removeLast();
          await cmd.undo();
          _redoStack.add(cmd);
        }
      } finally {
        _updateState(UndoRedoOperationType.undo);
      }
    } else {
      final redoIndex = _redoStack.indexOf(targetCommand);
      if (redoIndex != -1) {
        // redo elements up to the target to bring state forward
        final redoesCount = _redoStack.length - redoIndex;
        if (redoesCount <= 0) return;

        state = state.copyWith(isProcessing: true, lastOperationType: UndoRedoOperationType.redo);
        try {
          for (int i = 0; i < redoesCount; i++) {
            if (_redoStack.isEmpty) break;
            final cmd = _redoStack.removeLast();
            await cmd.execute();
            _undoStack.add(cmd);
          }
        } finally {
          _updateState(UndoRedoOperationType.redo);
        }
      }
    }
  }

  void _updateState(UndoRedoOperationType type) {
    state = UndoRedoState(
      canUndo: _undoStack.isNotEmpty,
      canRedo: _redoStack.isNotEmpty,
      isProcessing: false,
      lastOperationType: type,
      undoDescription: _undoStack.isNotEmpty ? _undoStack.last.description : null,
      redoDescription: _redoStack.isNotEmpty ? _redoStack.last.description : null,
      undoStack: List.unmodifiable(_undoStack),
      redoStack: List.unmodifiable(_redoStack),
    );
  }
}

final undoRedoProvider = NotifierProvider<UndoRedoNotifier, UndoRedoState>(() {
  return UndoRedoNotifier();
});
