enum TaskPlacement {
  top,
  middle,
  bottom;

  bool get isTop => this == TaskPlacement.top;
  bool get isMiddle => this == TaskPlacement.middle;
  bool get isBottom => this == TaskPlacement.bottom;
}
