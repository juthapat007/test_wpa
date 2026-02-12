// import 'package:flutter/foundation.dart';

// /// 🔍 Real-Time Chat Logger
// /// ใช้สำหรับ debug การส่งข้อความระหว่าง 2 users
// class ChatLogger {
//   static const bool _enabled = true; // เปลี่ยนเป็น false เพื่อปิด log

//   // สีสำหรับแยก log ใน terminal (VSCode, Android Studio รองรับ)
//   static const String _reset = '\x1B[0m';
//   static const String _red = '\x1B[31m';
//   static const String _green = '\x1B[32m';
//   static const String _yellow = '\x1B[33m';
//   static const String _blue = '\x1B[34m';
//   static const String _magenta = '\x1B[35m';
//   static const String _cyan = '\x1B[36m';
//   static const String _white = '\x1B[37m';
//   static const String _bold = '\x1B[1m';

//   /// 🔌 WebSocket Connection
//   static void connection(String message, {bool success = true}) {
//     if (!_enabled) return;
//     final color = success ? _green : _red;
//     final icon = success ? '✅' : '❌';
//     debugPrint('$color$_bold$icon WebSocket Connection: $message$_reset');
//   }

//   /// 📡 Subscription Events
//   static void subscription(String action, String? roomId) {
//     if (!_enabled) return;
//     final room = roomId != null ? 'room_id: $roomId' : 'all rooms';
//     debugPrint('$_cyan$_bold📡 Subscription [$action]: $room$_reset');
//   }

//   /// 📤 Outgoing Message (ส่งข้อความ)
//   static void outgoing({
//     required String senderId,
//     required String receiverId,
//     required String content,
//     String? messageId,
//   }) {
//     if (!_enabled) return;

//     final timestamp = DateTime.now().toIso8601String();

//     debugPrint('$_blue$_bold');
//     debugPrint('╔═══════════════════════════════════════════════════════════╗');
//     debugPrint('║  📤 OUTGOING MESSAGE                                      ║');
//     debugPrint('╠═══════════════════════════════════════════════════════════╣');
//     debugPrint('║  Time:        $timestamp                ║');
//     debugPrint(
//       '║  Message ID:  ${messageId ?? 'temp_' + DateTime.now().millisecondsSinceEpoch.toString()}',
//     );
//     debugPrint(
//       '║  From:        User #$senderId                                  ║',
//     );
//     debugPrint(
//       '║  To:          User #$receiverId                                  ║',
//     );
//     debugPrint('║  Content:     "$content"                           ║');
//     debugPrint('╚═══════════════════════════════════════════════════════════╝');
//     debugPrint(_reset);
//   }

//   /// 📥 Incoming Message (รับข้อความ)
//   static void incoming({
//     required String senderId,
//     required String receiverId,
//     required String content,
//     required String messageId,
//     bool isRead = false,
//   }) {
//     if (!_enabled) return;

//     final timestamp = DateTime.now().toIso8601String();
//     final readStatus = isRead ? '✓✓ Read' : '✓ Delivered';

//     debugPrint('$_green$_bold');
//     debugPrint('╔═══════════════════════════════════════════════════════════╗');
//     debugPrint('║  📥 INCOMING MESSAGE                                      ║');
//     debugPrint('╠═══════════════════════════════════════════════════════════╣');
//     debugPrint('║  Time:        $timestamp                ║');
//     debugPrint('║  Message ID:  $messageId                              ║');
//     debugPrint(
//       '║  From:        User #$senderId                                  ║',
//     );
//     debugPrint(
//       '║  To:          User #$receiverId                                  ║',
//     );
//     debugPrint('║  Content:     "$content"                           ║');
//     debugPrint('║  Status:      $readStatus                              ║');
//     debugPrint('╚═══════════════════════════════════════════════════════════╝');
//     debugPrint(_reset);
//   }

//   /// 🔄 Message Flow (ติดตามการไหลของข้อความ)
//   static void flow(String stage, String messageId, String details) {
//     if (!_enabled) return;
//     debugPrint('$_yellow$_bold🔄 [$stage] Message $messageId: $details$_reset');
//   }

//   /// ⚠️ Warning/Error
//   static void warning(String message) {
//     if (!_enabled) return;
//     debugPrint('$_yellow$_bold⚠️  WARNING: $message$_reset');
//   }

//   static void error(String message, {Object? error, StackTrace? stackTrace}) {
//     if (!_enabled) return;
//     debugPrint('$_red$_bold❌ ERROR: $message$_reset');
//     if (error != null) {
//       debugPrint('$_red   Details: $error$_reset');
//     }
//     if (stackTrace != null) {
//       debugPrint('$_red   Stack: $stackTrace$_reset');
//     }
//   }

//   /// 🎯 User Action
//   static void userAction(String userId, String action) {
//     if (!_enabled) return;
//     debugPrint('$_magenta$_bold🎯 User #$userId: $action$_reset');
//   }

//   /// 📊 State Change
//   static void stateChange(String from, String to) {
//     if (!_enabled) return;
//     debugPrint('$_cyan$_bold📊 State: $from → $to$_reset');
//   }

//   /// 🔍 Debug Detail
//   static void debug(String message) {
//     if (!_enabled) return;
//     debugPrint('$_white🔍 DEBUG: $message$_reset');
//   }

//   /// 📋 Summary (สรุปการส่งข้อความในช่วงเวลาหนึ่ง)
//   static void summary({
//     required int totalSent,
//     required int totalReceived,
//     required int duplicates,
//     required int errors,
//   }) {
//     if (!_enabled) return;

//     debugPrint('$_bold$_cyan');
//     debugPrint('╔═══════════════════════════════════════════════════════════╗');
//     debugPrint('║  📋 CHAT SESSION SUMMARY                                  ║');
//     debugPrint('╠═══════════════════════════════════════════════════════════╣');
//     debugPrint(
//       '║  Messages Sent:      $totalSent                              ║',
//     );
//     debugPrint(
//       '║  Messages Received:  $totalReceived                              ║',
//     );
//     debugPrint(
//       '║  Duplicates:         $duplicates                              ║',
//     );
//     debugPrint('║  Errors:             $errors                              ║');
//     debugPrint('╚═══════════════════════════════════════════════════════════╝');
//     debugPrint(_reset);
//   }

//   /// 🎬 Session Start/End
//   static void sessionStart(String userId, String partnerId) {
//     if (!_enabled) return;
//     debugPrint('$_bold$_green');
//     debugPrint('═══════════════════════════════════════════════════════════');
//     debugPrint('🎬 CHAT SESSION STARTED');
//     debugPrint('   Current User:  #$userId');
//     debugPrint('   Chat Partner:  #$partnerId');
//     debugPrint('   Time:          ${DateTime.now().toIso8601String()}');
//     debugPrint('═══════════════════════════════════════════════════════════');
//     debugPrint(_reset);
//   }

//   static void sessionEnd(String userId, String partnerId) {
//     if (!_enabled) return;
//     debugPrint('$_bold$_red');
//     debugPrint('═══════════════════════════════════════════════════════════');
//     debugPrint('🛑 CHAT SESSION ENDED');
//     debugPrint('   Current User:  #$userId');
//     debugPrint('   Chat Partner:  #$partnerId');
//     debugPrint('   Time:          ${DateTime.now().toIso8601String()}');
//     debugPrint('═══════════════════════════════════════════════════════════');
//     debugPrint(_reset);
//   }

//   /// 💬 Typing Indicator
//   static void typing(String userId, String partnerId, bool isTyping) {
//     if (!_enabled) return;
//     final action = isTyping ? 'started typing' : 'stopped typing';
//     debugPrint('$_yellow✍️  User #$userId $action to User #$partnerId$_reset');
//   }

//   /// ✓ Read Receipt
//   static void readReceipt(String messageId, String userId) {
//     if (!_enabled) return;
//     debugPrint('$_green✓✓ Message $messageId read by User #$userId$_reset');
//   }

//   /// 🔄 WebSocket Raw Message
//   static void rawWebSocket(String direction, String data) {
//     if (!_enabled) return;
//     final arrow = direction == 'send' ? '⬆️' : '⬇️';
//     final color = direction == 'send' ? _blue : _green;
//     debugPrint('$color$arrow WebSocket [$direction]: $data$_reset');
//   }
// }
