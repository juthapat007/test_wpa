// import 'package:flutter/material.dart';

// class ProfileAvatar extends StatelessWidget {
//   final String avatarUrl;

//   const ProfileAvatar({super.key, required this.avatarUrl});

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Stack(
//         children: [
//           // Avatar circle
//           Container(
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               border: Border.all(color: Colors.white, width: 4),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.1),
//                   blurRadius: 10,
//                   offset: const Offset(0, 4),
//                 ),
//               ],
//             ),
//             child: CircleAvatar(
//               radius: 50,
//               backgroundColor: Colors.grey[200],
//               backgroundImage: avatarUrl.isNotEmpty
//                   ? NetworkImage(avatarUrl)
//                   : null,
//               child: avatarUrl.isEmpty
//                   ? Icon(Icons.person, size: 50, color: Colors.grey[400])
//                   : null,
//             ),
//           ),

//           // Edit button with camera icon
//           Positioned(
//             bottom: 0,
//             right: 0,
//             child: GestureDetector(
//               onTap: () {
//                 // TODO: Implement avatar upload
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(
//                     content: Text('Upload avatar feature coming soon'),
//                     duration: Duration(seconds: 2),
//                   ),
//                 );
//               },
//               child: Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: Colors.blue,
//                   shape: BoxShape.circle,
//                   border: Border.all(color: Colors.white, width: 3),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.2),
//                       blurRadius: 6,
//                       offset: const Offset(0, 2),
//                     ),
//                   ],
//                 ),
//                 child: const Icon(
//                   Icons.camera_alt,
//                   size: 16,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String avatarUrl;

  const ProfileAvatar({super.key, required this.avatarUrl});

  @override

  Widget build(BuildContext context) {
    final imageUrl = avatarUrl.trim();

    return Center(
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipOval(
          child: imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: 110,
                  height: 110,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return _defaultAvatar();
                  },
                )
              : _defaultAvatar(),
        ),
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: Colors.grey[200],
      child: Icon(Icons.person, size: 50, color: Colors.grey[400]),
    );
  }
}
