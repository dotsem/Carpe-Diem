enum TaskPlacement {
  top,
  middle,
  bottom,
  urgent;

  bool get isTop => this == TaskPlacement.top;
  bool get isMiddle => this == TaskPlacement.middle;
  bool get isBottom => this == TaskPlacement.bottom;
  bool get isUrgent => this == TaskPlacement.urgent;

  String get name => switch (this) {
    TaskPlacement.top => "Top",
    TaskPlacement.middle => "Middle",
    TaskPlacement.bottom => "Bottom",
    TaskPlacement.urgent => "Urgent",
  };
}
