// import 'package:flutter/cupertino.dart';

// class AppImage extends StatelessWidget {
//   final String? imageUrl;
//   final double size;

//   const AppImage({super.key, this.imageUrl, this.size = 40});

//   @override
//   Widget build(BuildContext context) {
//     if (imageUrl == null || imageUrl!.isEmpty) {
//       return Image.asset(
//         'assets/images/placeholder.png',
//         width: size,
//         height: size,
//         fit: BoxFit.cover,
//       );
//     }

//     return Image.network(
//       imageUrl!,
//       width: size,
//       height: size,
//       fit: BoxFit.cover,
//       errorBuilder: (_, __, ___) {
//         return Image.asset(
//           'assets/images/placeholder.png',
//           width: size,
//           height: size,
//         );
//       },
//     );
//   }
// }
