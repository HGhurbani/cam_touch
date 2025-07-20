// lib/core/models/pigeon_user_details.dart

import 'package:firebase_auth/firebase_auth.dart'; // استيراد Firebase User

class PigeonUserDetails { // يمكنك إعادة تسمية هذا الكلاس إلى UserDetails أو AppUser
  final String? uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final bool? emailVerified;
  final String? phoneNumber;
  // أضف أي حقول أخرى تحتاجها من Firebase User
  // final List<String>? providerIds;
  // final int? creationTime;
  // final int? lastSignInTime;

  PigeonUserDetails({
    this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    this.emailVerified,
    this.phoneNumber,
    // this.providerIds,
    // this.creationTime,
    // this.lastSignInTime,
  });

  // دالة تحويل (factory constructor) لتحويل كائن Firebase User إلى PigeonUserDetails
  factory PigeonUserDetails.fromFirebaseUser(User user) {
    return PigeonUserDetails(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoURL: user.photoURL,
      emailVerified: user.emailVerified,
      phoneNumber: user.phoneNumber,
      // providerIds: user.providerData.map((info) => info.providerId).toList(),
      // creationTime: user.metadata?.creationTime?.millisecondsSinceEpoch,
      // lastSignInTime: user.metadata?.lastSignInTime?.millisecondsSinceEpoch,
    );
  }

  // يمكنك إضافة دالة toMap أو toJson هنا إذا كنت بحاجة لتحويل الكائن إلى Map أو JSON
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'emailVerified': emailVerified,
      'phoneNumber': phoneNumber,
    };
  }

// يمكنك إضافة دالة fromMap أو fromJson هنا إذا كنت تقرأ من Firestore مثلاً
// factory PigeonUserDetails.fromMap(Map<String, dynamic> map) {
//   return PigeonUserDetails(
//     uid: map['uid'],
//     email: map['email'],
//     displayName: map['displayName'],
//     photoURL: map['photoURL'],
//     emailVerified: map['emailVerified'],
//     phoneNumber: map['phoneNumber'],
//   );
// }
}