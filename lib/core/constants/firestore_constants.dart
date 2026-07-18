/// FirestoreCollections holds all collection names in Cloud Firestore.
class FirestoreCollections {
  FirestoreCollections._();

  static const String users = 'USERS';
  static const String userImages = 'USER_IMAGES';
  static const String fixedOtp = 'fixed_otp';
  static const String committeeMembers = 'COMMITTEE_MEMBERS';
  static const String meetingMinutes = 'MEETING_MINUTES';
  static const String governmentOrders = 'GOVERNMENT_ORDERS';
  static const String formsCirculars = 'FORMS_CIRCULARS';
  static const String chunksSubcollection = 'CHUNKS';
  static const String admins = 'ADMINS';
  static const String zones = 'ZONES';
  static const String zonalMembers = 'ZONAL_MEMBERS';
  static const String updates = 'UPDATES';
  static const String notifications = 'NOTIFICATIONS';
  static const String liveSessions = 'LIVE_SESSIONS';
  static const String gallery = 'GALLERY';
  static const String videos = 'VIDEOS';
  static const String videoProgress = 'VIDEO_PROGRESS';
  static const String ads = 'ADS';
  static const String events = 'EVENTS';
  static const String designations = 'DESIGNATIONS';
}

/// FirestoreFields holds all field names inside firestore documents to prevent hardcoding.
class FirestoreFields {
  FirestoreFields._();

  // User document fields
  static const String uid = 'uid';
  static const String name = 'name';
  static const String phoneNumber = 'phoneNumber';
  static const String designation = 'designation';
  static const String institution = 'institution';
  static const String profileImageId = 'profileImageId';
  static const String isApproved = 'isApproved';
  static const String status = 'status';
  static const String createdAt = 'createdAt';
  
  // Image document fields
  static const String imageBase64 = 'imageBase64';
  static const String updatedAt = 'updatedAt';
  
  // OTP fields
  static const String otp = 'otp';
}
