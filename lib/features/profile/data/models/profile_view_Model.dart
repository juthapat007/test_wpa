import 'package:equatable/equatable.dart';

class ProfileViewModel {
  final String name;
  final String title;
  final String avatarUrl;
  final String companyName;
  final String teamName;
  final bool pushNotifications;
  final bool emailNotifications;

  const ProfileViewModel({
    required this.name,
    required this.title,
    required this.avatarUrl,
    required this.companyName,
    required this.teamName,
    required this.pushNotifications,
    required this.emailNotifications,
  });

  ProfileViewModel copyWith({
    bool? pushNotifications,
    bool? emailNotifications,
  }) {
    return ProfileViewModel(
      name: name,
      title: title,
      avatarUrl: avatarUrl,
      companyName: companyName,
      teamName: teamName,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
    );
  }

  @override
  List<Object?> get props => [
    name,
    title,
    avatarUrl,
    pushNotifications,
    emailNotifications,
  ];
}
