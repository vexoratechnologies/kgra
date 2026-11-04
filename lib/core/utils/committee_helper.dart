import '../../features/auth/data/models/user_model.dart';

/// CommitteeHelper provides centralized filtering, ranking, and designation logic
/// for State Committee and Executive Committee members.
class CommitteeHelper {
  CommitteeHelper._();

  /// Default designations that can be assigned to State Committee members
  static const List<String> defaultStateDesignations = [
    'President',
    'Vice President',
    'General Secretary',
    'Secretary',
    'Treasurer',
    'Joint Secretary',
    'State Committee Member',
  ];

  /// Default designations that can be assigned to Executive Committee members
  static const List<String> defaultExecutiveDesignations = [
    'President',
    'Vice President',
    'General Secretary',
    'Secretary',
    'Treasurer',
    'Joint Secretary',
    'Executive Committee Member',
  ];

  /// Checks whether a user is an explicitly added member of the State Committee.
  /// Does NOT automatically pull zonal presidents/secretaries.
  static bool isStateCommitteeMember(UserModel user) {
    if (user.stateCommitteeRole != null && user.stateCommitteeRole!.trim().isNotEmpty) {
      return true;
    }
    // Backward compatibility for users whose designated title was explicitly "State Committee Member"
    final des = user.designation?.trim().toLowerCase() ?? '';
    return des == 'state committee member';
  }

  /// Checks whether a user is an explicitly added member of the Executive Committee.
  /// Does NOT automatically pull zonal presidents/secretaries.
  static bool isExecutiveCommitteeMember(UserModel user) {
    if (user.executiveCommitteeRole != null && user.executiveCommitteeRole!.trim().isNotEmpty) {
      return true;
    }
    // Backward compatibility for users whose designated title was explicitly "Executive Committee Member"
    final des = user.designation?.trim().toLowerCase() ?? '';
    return des == 'executive committee member' || des == 'executive commitee member';
  }

  /// Returns a numeric ranking for a designation (lower number = higher position).
  static int getRank(String designation) {
    final lower = designation.trim().toLowerCase();
    if (lower.contains('vice president') || lower.contains('vice-president')) return 2;
    if (lower.contains('president')) return 1;
    if (lower.contains('general secretary') || lower.contains('gen secretary') || lower.contains('gen. secretary')) return 3;
    if (lower.contains('joint secretary') || lower.contains('joint-secretary')) return 6;
    if (lower.contains('secretary')) return 4;
    if (lower.contains('treasurer')) return 5;
    if (lower.contains('committee member')) return 7;
    return 10;
  }

  /// Returns the most appropriate display designation for a user within a committee context.
  static String getDisplayDesignation(UserModel user, bool isState) {
    if (isState) {
      if (user.stateCommitteeRole != null && user.stateCommitteeRole!.trim().isNotEmpty) {
        return user.stateCommitteeRole!;
      }
      return user.designation ?? 'State Committee Member';
    } else {
      if (user.executiveCommitteeRole != null && user.executiveCommitteeRole!.trim().isNotEmpty) {
        return user.executiveCommitteeRole!;
      }
      return user.designation ?? 'Executive Committee Member';
    }
  }

  /// Sorts a list of members by their committee rank (President first, then Secretary, etc.),
  /// and alphabetically by name for members with the same rank.
  static List<UserModel> sortMembers(List<UserModel> members, bool isState) {
    final copy = List<UserModel>.from(members);
    copy.sort((a, b) {
      final rankA = getRank(getDisplayDesignation(a, isState));
      final rankB = getRank(getDisplayDesignation(b, isState));
      if (rankA != rankB) {
        return rankA.compareTo(rankB);
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return copy;
  }

  /// Sorts zonal members by rank (President first, Secretary, etc.), then alphabetically by name.
  static List<UserModel> sortZonalMembers(List<UserModel> members) {
    final copy = List<UserModel>.from(members);
    copy.sort((a, b) {
      final desA = a.designation ?? 'Member';
      final desB = b.designation ?? 'Member';
      final rankA = getRank(desA);
      final rankB = getRank(desB);
      if (rankA != rankB) {
        return rankA.compareTo(rankB);
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return copy;
  }

  /// Helper to compare two zone strings flexibly (handling "Thrissur", "Thrissur Zone", etc.).
  static bool matchesZone(String? userZone, String? filterZone) {
    if (filterZone == null || filterZone.isEmpty || filterZone.trim().toLowerCase() == 'all') {
      return true;
    }
    if (userZone == null || userZone.trim().isEmpty) {
      return false;
    }
    final cleanUser = userZone.trim().toLowerCase().replaceAll(RegExp(r'\bzone\b'), '').trim();
    final cleanFilter = filterZone.trim().toLowerCase().replaceAll(RegExp(r'\bzone\b'), '').trim();
    if (cleanUser == cleanFilter) return true;
    return cleanUser.contains(cleanFilter) || cleanFilter.contains(cleanUser);
  }
}
