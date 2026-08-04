Future<bool> downloadCsv(String filename, String csvContent) async {
  // Non-web platforms: no-op (you can wire share/file-saver later)
  return false;
}
