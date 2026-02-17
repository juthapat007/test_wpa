// // lib/features/other_profile/presentation/pages/other_profile_page.dart

// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:test_wpa/core/constants/set_space.dart';
// import 'package:test_wpa/core/theme/app_colors.dart' as color;
// import 'package:test_wpa/features/other_profile/domain/entities/profile_detail.dart';
// import 'package:test_wpa/features/other_profile/presentation/bloc/profile_detail_bloc.dart';
// import 'package:test_wpa/features/other_profile/presentation/bloc/profile_detail_event.dart';
// import 'package:test_wpa/features/other_profile/presentation/bloc/profile_detail_state.dart';
// import 'package:test_wpa/features/schedules/domain/entities/schedule_item.dart';
// import 'package:test_wpa/features/widgets/app_button.dart';
// import 'package:intl/intl.dart';

// class OtherProfilePage extends StatefulWidget {
//   final int delegateId; // ✅ รับ delegateId แทน Delegate object

//   const OtherProfilePage({super.key, required this.delegateId});

//   @override
//   State<OtherProfilePage> createState() => _OtherProfilePageState();
// }

// class _OtherProfilePageState extends State<OtherProfilePage> {
//   // ✅ ไม่ต้องมี initState เพราะ BLoC ได้ trigger LoadProfileDetail แล้วที่ app_module

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: color.AppColors.background,
//       appBar: AppBar(
//         title: const Text('Profile'),
//         backgroundColor: color.AppColors.surface,
//         elevation: 0,
//       ),
//       body: BlocListener<ProfileDetailBloc, ProfileDetailState>(
//         listener: (context, state) {
//           if (state is FriendRequestSuccess) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text(state.message),
//                 backgroundColor: color.AppColors.success,
//               ),
//             );
//           } else if (state is FriendRequestFailed) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text(state.message),
//                 backgroundColor: color.AppColors.error,
//               ),
//             );
//           }
//         },
//         child: BlocBuilder<ProfileDetailBloc, ProfileDetailState>(
//           builder: (context, state) {
//             if (state is ProfileDetailLoading) {
//               return const Center(
//                 child: CircularProgressIndicator(
//                   color: color.AppColors.primary,
//                 ),
//               );
//             }

//             if (state is ProfileDetailError) {
//               return Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Icon(
//                       Icons.error_outline,
//                       size: 64,
//                       color: color.AppColors.error,
//                     ),
//                     SizedBox(height: space.m),
//                     Text(
//                       state.message,
//                       style: const TextStyle(color: color.AppColors.error),
//                     ),
//                     SizedBox(height: space.l),
//                     ElevatedButton(
//                       onPressed: () {
//                         context.read<ProfileDetailBloc>().add(
//                           LoadProfileDetail(widget.delegateId),
//                         );
//                       },
//                       child: const Text('ลองใหม่'),
//                     ),
//                   ],
//                 ),
//               );
//             }

//             if (state is ProfileDetailLoaded || state is FriendRequestSending) {
//               final profile = state is ProfileDetailLoaded
//                   ? state.profile
//                   : null;

//               if (profile == null) {
//                 return const Center(child: Text('No profile data'));
//               }

//               final schedules = state is ProfileDetailLoaded
//                   ? state.schedules
//                   : null;

//               return SingleChildScrollView(
//                 child: Column(
//                   children: [
//                     // Profile Section
//                     _buildProfileSection(profile, context),

//                     const SizedBox(height: space.l),

//                     // Schedule Section
//                     if (schedules != null && schedules.isNotEmpty)
//                       _buildScheduleSection(schedules, profile.name),
//                   ],
//                 ),
//               );
//             }

//             return const SizedBox.shrink();
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildProfileSection(ProfileDetail profile, BuildContext context) {
//     return Container(
//       width: double.infinity,
//       decoration: BoxDecoration(
//         color: color.AppColors.surface,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             // Avatar
//             Hero(
//               tag: 'avatar_${profile.id}',
//               child: CircleAvatar(
//                 radius: 60,
//                 backgroundImage: profile.avatarUrl.isNotEmpty
//                     ? NetworkImage(profile.avatarUrl)
//                     : null,
//                 backgroundColor: color.AppColors.primary.withOpacity(0.1),
//                 child: profile.avatarUrl.isEmpty
//                     ? Text(
//                         profile.name.substring(0, 1).toUpperCase(),
//                         style: const TextStyle(
//                           fontSize: 40,
//                           fontWeight: FontWeight.bold,
//                           color: color.AppColors.primary,
//                         ),
//                       )
//                     : null,
//               ),
//             ),

//             SizedBox(height: space.l),

//             // Name
//             Text(
//               profile.name,
//               style: const TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: color.AppColors.textPrimary,
//               ),
//               textAlign: TextAlign.center,
//             ),

//             SizedBox(height: space.xs),

//             // Title
//             if (profile.title != null && profile.title!.isNotEmpty)
//               Text(
//                 profile.title!,
//                 style: const TextStyle(
//                   fontSize: 16,
//                   color: color.AppColors.textSecondary,
//                 ),
//                 textAlign: TextAlign.center,
//               ),

//             SizedBox(height: space.m),

//             // Company
//             _buildInfoRow(
//               icon: Icons.business,
//               label: 'Company',
//               value: profile.companyName,
//             ),

//             // Email
//             _buildInfoRow(
//               icon: Icons.email,
//               label: 'Email',
//               value: profile.email,
//             ),

//             // Country
//             _buildInfoRow(
//               icon: Icons.flag,
//               label: 'Country',
//               value: profile.countryCode,
//             ),

//             SizedBox(height: space.xl),

//             // Connection Status & Actions
//             _buildConnectionSection(profile, context),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildScheduleSection(List<ScheduleItem> schedules, String userName) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       decoration: BoxDecoration(
//         color: color.AppColors.surface,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: color.AppColors.primary.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: const Icon(
//                     Icons.calendar_today,
//                     color: color.AppColors.primary,
//                     size: 20,
//                   ),
//                 ),
//                 const SizedBox(width: space.m),
//                 Expanded(
//                   child: Text(
//                     '$userName\'s Schedule',
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: color.AppColors.textPrimary,
//                     ),
//                   ),
//                 ),
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 12,
//                     vertical: 6,
//                   ),
//                   decoration: BoxDecoration(
//                     color: color.AppColors.primary.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Text(
//                     '${schedules.length} events',
//                     style: const TextStyle(
//                       fontSize: 12,
//                       fontWeight: FontWeight.w600,
//                       color: color.AppColors.primary,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const Divider(height: 1),
//           ListView.separated(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             padding: const EdgeInsets.all(16),
//             itemCount: schedules.length,
//             separatorBuilder: (context, index) =>
//                 const SizedBox(height: space.m),
//             itemBuilder: (context, index) {
//               return _buildScheduleCard(schedules[index]);
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildScheduleCard(ScheduleItem schedule) {
//     final dateFormat = DateFormat('MMM dd, yyyy');
//     final timeFormat = DateFormat('HH:mm');

//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: color.AppColors.background,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: color.AppColors.primary.withOpacity(0.2)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Title & Type
//           Row(
//             children: [
//               Expanded(
//                 child: Text(
//                   schedule.title,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                     color: color.AppColors.textPrimary,
//                   ),
//                 ),
//               ),
//               if (schedule.type != null)
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 8,
//                     vertical: 4,
//                   ),
//                   decoration: BoxDecoration(
//                     color: color.AppColors.secondary.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Text(
//                     schedule.type!,
//                     style: const TextStyle(
//                       fontSize: 11,
//                       fontWeight: FontWeight.w600,
//                       color: color.AppColors.secondary,
//                     ),
//                   ),
//                 ),
//             ],
//           ),

//           if (schedule.description != null &&
//               schedule.description!.isNotEmpty) ...[
//             const SizedBox(height: space.s),
//             Text(
//               schedule.description!,
//               style: const TextStyle(
//                 fontSize: 14,
//                 color: color.AppColors.textSecondary,
//               ),
//             ),
//           ],

//           const SizedBox(height: space.m),

//           // Time & Location
//           Row(
//             children: [
//               Icon(
//                 Icons.access_time,
//                 size: 16,
//                 color: color.AppColors.textSecondary,
//               ),
//               const SizedBox(width: space.xs),
//               Text(
//                 '${timeFormat.format(schedule.startTime)} - ${timeFormat.format(schedule.endTime)}',
//                 style: const TextStyle(
//                   fontSize: 13,
//                   color: color.AppColors.textSecondary,
//                 ),
//               ),
//               const SizedBox(width: space.m),
//               Icon(
//                 Icons.calendar_today,
//                 size: 16,
//                 color: color.AppColors.textSecondary,
//               ),
//               const SizedBox(width: space.xs),
//               Text(
//                 dateFormat.format(schedule.startTime),
//                 style: const TextStyle(
//                   fontSize: 13,
//                   color: color.AppColors.textSecondary,
//                 ),
//               ),
//             ],
//           ),

//           if (schedule.location != null && schedule.location!.isNotEmpty) ...[
//             const SizedBox(height: space.s),
//             Row(
//               children: [
//                 Icon(
//                   Icons.location_on,
//                   size: 16,
//                   color: color.AppColors.textSecondary,
//                 ),
//                 const SizedBox(width: space.xs),
//                 Expanded(
//                   child: Text(
//                     schedule.location!,
//                     style: const TextStyle(
//                       fontSize: 13,
//                       color: color.AppColors.textSecondary,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildInfoRow({
//     required IconData icon,
//     required String label,
//     required String value,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         children: [
//           Icon(icon, size: 20, color: color.AppColors.textSecondary),
//           SizedBox(width: space.s),
//           Text(
//             '$label: ',
//             style: const TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.w600,
//               color: color.AppColors.textSecondary,
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: const TextStyle(
//                 fontSize: 14,
//                 color: color.AppColors.textPrimary,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildConnectionSection(ProfileDetail profile, BuildContext context) {
//     return Column(
//       children: [
//         // Connection Status Badge
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//           decoration: BoxDecoration(
//             color: profile.isConnected
//                 ? color.AppColors.success.withOpacity(0.1)
//                 : color.AppColors.warning.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(20),
//             border: Border.all(
//               color: profile.isConnected
//                   ? color.AppColors.success
//                   : color.AppColors.warning,
//               width: 1,
//             ),
//           ),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(
//                 profile.isConnected ? Icons.people : Icons.person_add_disabled,
//                 size: 18,
//                 color: profile.isConnected
//                     ? color.AppColors.success
//                     : color.AppColors.warning,
//               ),
//               SizedBox(width: space.xs),
//               Text(
//                 profile.isConnected ? '✓ Connected' : 'Not Connected',
//                 style: TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w600,
//                   color: profile.isConnected
//                       ? color.AppColors.success
//                       : color.AppColors.warning,
//                 ),
//               ),
//             ],
//           ),
//         ),

//         SizedBox(height: space.l),

//         // Add Friend Button (only show if not connected)
//         // if (!profile.isConnected)
//         //   AppButton(
//         //     text: 'Add Friend',
//         //     backgroundColor: color.AppColors.primary,
//         //     textColor: color.AppColors.textOnPrimary,
//         //     onPressed: () {
//         //       context.read<ProfileDetailBloc>().add(
//         //         SendFriendRequest(profile.id),
//         //       );
//         //     },
//         //   ),

//         // Message Button (if connected)
//         if (profile.isConnected) ...[
//           AppButton(
//             text: 'Send Message',
//             backgroundColor: color.AppColors.primary,
//             textColor: color.AppColors.textOnPrimary,
//             onPressed: () {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text('Chat feature coming soon!')),
//               );
//             },
//           ),
//         ],
//       ],
//     );
//   }
// }
// lib/features/other_profile/presentation/pages/other_profile_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/core/theme/app_colors.dart' as color;
import 'package:test_wpa/features/other_profile/domain/entities/profile_detail.dart';
import 'package:test_wpa/features/other_profile/presentation/bloc/profile_detail_bloc.dart';
import 'package:test_wpa/features/other_profile/presentation/bloc/profile_detail_event.dart';
import 'package:test_wpa/features/other_profile/presentation/bloc/profile_detail_state.dart';
import 'package:test_wpa/features/schedules/domain/entities/schedule_item.dart';
import 'package:test_wpa/features/widgets/app_button.dart';
import 'package:intl/intl.dart';

class OtherProfilePage extends StatefulWidget {
  final int delegateId; // ✅ รับ delegateId แทน Delegate object

  const OtherProfilePage({super.key, required this.delegateId});

  @override
  State<OtherProfilePage> createState() => _OtherProfilePageState();
}

class _OtherProfilePageState extends State<OtherProfilePage> {
  // ✅ ไม่ต้องมี initState เพราะ BLoC ได้ trigger LoadProfileDetail แล้วที่ app_module

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color.AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: color.AppColors.surface,
        elevation: 0,
      ),
      body: BlocBuilder<ProfileDetailBloc, ProfileDetailState>(
        builder: (context, state) {
          if (state is ProfileDetailLoading) {
            return const Center(
              child: CircularProgressIndicator(color: color.AppColors.primary),
            );
          }

          if (state is ProfileDetailError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: color.AppColors.error,
                  ),
                  SizedBox(height: space.m),
                  Text(
                    state.message,
                    style: const TextStyle(color: color.AppColors.error),
                  ),
                  SizedBox(height: space.l),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ProfileDetailBloc>().add(
                        LoadProfileDetail(widget.delegateId),
                      );
                    },
                    child: const Text('ลองใหม่'),
                  ),
                ],
              ),
            );
          }

          if (state is ProfileDetailLoaded || state is FriendRequestSending) {
            final profile = state is ProfileDetailLoaded ? state.profile : null;

            if (profile == null) {
              return const Center(child: Text('No profile data'));
            }

            final schedules = state is ProfileDetailLoaded
                ? state.schedules
                : null;

            return SingleChildScrollView(
              child: Column(
                children: [
                  // Profile Section
                  _buildProfileSection(profile, context),

                  const SizedBox(height: space.l),

                  // Schedule Section
                  if (schedules != null && schedules.isNotEmpty)
                    _buildScheduleSection(schedules, profile.name),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildProfileSection(ProfileDetail profile, BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            Hero(
              tag: 'avatar_${profile.id}',
              child: CircleAvatar(
                radius: 60,
                backgroundImage: profile.avatarUrl.isNotEmpty
                    ? NetworkImage(profile.avatarUrl)
                    : null,
                backgroundColor: color.AppColors.primary.withOpacity(0.1),
                child: profile.avatarUrl.isEmpty
                    ? Text(
                        profile.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: color.AppColors.primary,
                        ),
                      )
                    : null,
              ),
            ),

            SizedBox(height: space.l),

            // Name
            Text(
              profile.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color.AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: space.xs),

            // Title
            if (profile.title != null && profile.title!.isNotEmpty)
              Text(
                profile.title!,
                style: const TextStyle(
                  fontSize: 16,
                  color: color.AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

            SizedBox(height: space.m),

            // Company
            _buildInfoRow(
              icon: Icons.business,
              label: 'Company',
              value: profile.companyName,
            ),

            // Email
            _buildInfoRow(
              icon: Icons.email,
              label: 'Email',
              value: profile.email,
            ),

            // Country
            _buildInfoRow(
              icon: Icons.flag,
              label: 'Country',
              value: profile.countryCode,
            ),

            SizedBox(height: space.xl),

            // Connection Status & Actions
            _buildConnectionSection(profile, context),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleSection(List<ScheduleItem> schedules, String userName) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: color.AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: color.AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: space.m),
                Expanded(
                  child: Text(
                    '$userName\'s Schedule',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color.AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${schedules.length} events',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color.AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: schedules.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: space.m),
            itemBuilder: (context, index) {
              return _buildScheduleCard(schedules[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(ScheduleItem schedule) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & Type
          Row(
            children: [
              Expanded(
                child: Text(
                  schedule.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color.AppColors.textPrimary,
                  ),
                ),
              ),
              if (schedule.type != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    schedule.type!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color.AppColors.secondary,
                    ),
                  ),
                ),
            ],
          ),

          if (schedule.description != null &&
              schedule.description!.isNotEmpty) ...[
            const SizedBox(height: space.s),
            Text(
              schedule.description!,
              style: const TextStyle(
                fontSize: 14,
                color: color.AppColors.textSecondary,
              ),
            ),
          ],

          const SizedBox(height: space.m),

          // Time & Location
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16,
                color: color.AppColors.textSecondary,
              ),
              const SizedBox(width: space.xs),
              Text(
                '${timeFormat.format(schedule.startTime)} - ${timeFormat.format(schedule.endTime)}',
                style: const TextStyle(
                  fontSize: 13,
                  color: color.AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: space.m),
              Icon(
                Icons.calendar_today,
                size: 16,
                color: color.AppColors.textSecondary,
              ),
              const SizedBox(width: space.xs),
              Text(
                dateFormat.format(schedule.startTime),
                style: const TextStyle(
                  fontSize: 13,
                  color: color.AppColors.textSecondary,
                ),
              ),
            ],
          ),

          if (schedule.location != null && schedule.location!.isNotEmpty) ...[
            const SizedBox(height: space.s),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: color.AppColors.textSecondary,
                ),
                const SizedBox(width: space.xs),
                Expanded(
                  child: Text(
                    schedule.location!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: color.AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color.AppColors.textSecondary),
          SizedBox(width: space.s),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color.AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: color.AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionSection(ProfileDetail profile, BuildContext context) {
    return Column(
      children: [
        // Connection Status Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: profile.isConnected
                ? color.AppColors.success.withOpacity(0.1)
                : color.AppColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: profile.isConnected
                  ? color.AppColors.success
                  : color.AppColors.warning,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                profile.isConnected ? Icons.people : Icons.person_add_disabled,
                size: 18,
                color: profile.isConnected
                    ? color.AppColors.success
                    : color.AppColors.warning,
              ),
              SizedBox(width: space.xs),
              Text(
                profile.isConnected ? '✓ Connected' : 'Not Connected',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: profile.isConnected
                      ? color.AppColors.success
                      : color.AppColors.warning,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: space.l),

        // TODO: Add Friend Button - รอ backend พร้อมก่อน
        // if (!profile.isConnected)
        //   AppButton(
        //     text: 'Add Friend',
        //     backgroundColor: color.AppColors.primary,
        //     textColor: color.AppColors.textOnPrimary,
        //     onPressed: () {
        //       context.read<ProfileDetailBloc>().add(
        //         SendFriendRequest(profile.id),
        //       );
        //     },
        //   ),

        // Message Button (if connected)
        if (profile.isConnected) ...[
          AppButton(
            text: 'Send Message',
            backgroundColor: color.AppColors.primary,
            textColor: color.AppColors.textOnPrimary,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat feature coming soon!')),
              );
            },
          ),
        ],
      ],
    );
  }
}
