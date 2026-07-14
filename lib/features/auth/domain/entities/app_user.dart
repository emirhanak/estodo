class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.isAnonymous,
    this.displayName,
  });

  final String id;
  final String email;
  final bool isAnonymous;
  final String? displayName;
}
