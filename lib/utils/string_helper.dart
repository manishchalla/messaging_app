class StringHelper {
  static String getInitials(String displayName) {
    if (displayName.isEmpty) return "?";

    final names = displayName.trim().split(" ");
    if (names.length >= 2) {
      return "${names[0][0]}${names[1][0]}".toUpperCase();
    }
    return displayName[0].toUpperCase();
  }
}