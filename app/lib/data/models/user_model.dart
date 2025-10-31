import 'package:equatable/equatable.dart';
import '../../core/utils/base_model.dart';

/// User model
class UserModel extends BaseModelWithId {
  final String email;
  final String name;
  final String? avatar;
  final UserRole role;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final Map<String, dynamic>? preferences;
  final String? phone;
  final String? dateOfBirth;
  final String? bio;
  final LocationModel? location;
  final List<String>? subjects;
  final double? rating;
  final int? totalSessions;

  const UserModel({
    required String id,
    required this.email,
    required this.name,
    this.avatar,
    required this.role,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.preferences,
    this.phone,
    this.dateOfBirth,
    this.bio,
    this.location,
    this.subjects,
    this.rating,
    this.totalSessions,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatar': avatar,
      'role': role.toString(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isActive': isActive,
      'preferences': preferences,
      'phone': phone,
      'dateOfBirth': dateOfBirth,
      'bio': bio,
      'location': location?.toJson(),
      'subjects': subjects,
      'rating': rating,
      'totalSessions': totalSessions,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.toString() == json['role'],
        orElse: () => UserRole.student,
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      isActive: json['isActive'] as bool? ?? true,
      preferences: json['preferences'] as Map<String, dynamic>?,
      phone: json['phone'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      bio: json['bio'] as String?,
      location: json['location'] != null
          ? LocationModel.fromJson(json['location'])
          : null,
      subjects: (json['subjects'] as List<dynamic>?)?.cast<String>(),
      rating: json['rating'] as double?,
      totalSessions: json['totalSessions'] as int?,
    );
  }

  @override
  UserModel copyWith() {
    return copyWith(
      email: email,
      name: name,
      avatar: avatar,
      role: role,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isActive: isActive,
      preferences: preferences,
      phone: phone,
      dateOfBirth: dateOfBirth,
      bio: bio,
      location: location,
      subjects: subjects,
      rating: rating,
      totalSessions: totalSessions,
    );
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? avatar,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    Map<String, dynamic>? preferences,
    String? phone,
    String? dateOfBirth,
    String? bio,
    LocationModel? location,
    List<String>? subjects,
    double? rating,
    int? totalSessions,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      preferences: preferences ?? this.preferences,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      subjects: subjects ?? this.subjects,
      rating: rating ?? this.rating,
      totalSessions: totalSessions ?? this.totalSessions,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        avatar,
        role,
        createdAt,
        updatedAt,
        isActive,
        preferences,
        phone,
        dateOfBirth,
        bio,
        location,
        subjects,
        rating,
        totalSessions,
      ];
}

/// User roles
enum UserRole {
  student,
  tutor,
  admin,
}

/// Location model
class LocationModel extends BaseModel with EquatableMixin {
  final String country;
  final String state;
  final String city;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? zipCode;

  const LocationModel({
    required this.country,
    required this.state,
    required this.city,
    this.address,
    this.latitude,
    this.longitude,
    this.zipCode,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'country': country,
      'state': state,
      'city': city,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'zipCode': zipCode,
    };
  }

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      country: json['country'] as String,
      state: json['state'] as String,
      city: json['city'] as String,
      address: json['address'] as String?,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      zipCode: json['zipCode'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        country,
        state,
        city,
        address,
        latitude,
        longitude,
        zipCode,
      ];
}

/// Subject model
class SubjectModel extends BaseModelWithId {
  final String name;
  final String description;
  final String? categoryId;
  final String? iconUrl;
  final String? color;
  final bool isActive;
  final int? totalTutors;
  final double? averageRating;
  final int? totalCourses;

  const SubjectModel({
    required String id,
    required this.name,
    required this.description,
    this.categoryId,
    this.iconUrl,
    this.color,
    this.isActive = true,
    this.totalTutors,
    this.averageRating,
    this.totalCourses,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'categoryId': categoryId,
      'iconUrl': iconUrl,
      'color': color,
      'isActive': isActive,
      'totalTutors': totalTutors,
      'averageRating': averageRating,
      'totalCourses': totalCourses,
    };
  }

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      categoryId: json['categoryId'] as String?,
      iconUrl: json['iconUrl'] as String?,
      color: json['color'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      totalTutors: json['totalTutors'] as int?,
      averageRating: json['averageRating'] as double?,
      totalCourses: json['totalCourses'] as int?,
    );
  }

  @override
  SubjectModel copyWith() {
    return copyWith();
  }

  SubjectModel copyWith({
    String? id,
    String? name,
    String? description,
    String? categoryId,
    String? iconUrl,
    String? color,
    bool? isActive,
    int? totalTutors,
    double? averageRating,
    int? totalCourses,
  }) {
    return SubjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      iconUrl: iconUrl ?? this.iconUrl,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      totalTutors: totalTutors ?? this.totalTutors,
      averageRating: averageRating ?? this.averageRating,
      totalCourses: totalCourses ?? this.totalCourses,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        categoryId,
        iconUrl,
        color,
        isActive,
        totalTutors,
        averageRating,
        totalCourses,
      ];
}

/// Tutor model
class TutorModel extends UserModel {
  final List<String> subjects;
  final List<String> certifications;
  final double hourlyRate;
  final String? bio;
  final int experienceYears;
  final double? rating;
  final int? totalSessions;
  final List<String>? languages;
  final List<AvailabilitySlot>? availability;
  final String? profileImage;
  final bool isOnline;
  final List<EducationModel>? education;
  final List<WorkExperienceModel>? workExperience;
  final String? description;
  final int? totalStudents;
  final String? timezone;

  const TutorModel({
    required String id,
    required String email,
    required String name,
    String? avatar,
    UserRole role = UserRole.tutor,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool isActive = true,
    Map<String, dynamic>? preferences,
    String? phone,
    String? dateOfBirth,
    LocationModel? location,
    List<String>? userSubjects,
    double? userRating,
    int? userTotalSessions,
    required this.subjects,
    required this.certifications,
    required this.hourlyRate,
    this.bio,
    required this.experienceYears,
    this.rating,
    this.totalSessions,
    this.languages,
    this.availability,
    this.profileImage,
    this.isOnline = false,
    this.education,
    this.workExperience,
    this.description,
    this.totalStudents,
    this.timezone,
  }) : super(
          id: id,
          email: email,
          name: name,
          avatar: avatar,
          role: role,
          createdAt: createdAt,
          updatedAt: updatedAt,
          isActive: isActive,
          preferences: preferences,
          phone: phone,
          dateOfBirth: dateOfBirth,
          location: location,
          subjects: userSubjects,
          rating: userRating,
          totalSessions: userTotalSessions,
        );

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'subjects': subjects,
      'certifications': certifications,
      'hourlyRate': hourlyRate,
      'bio': bio,
      'experienceYears': experienceYears,
      'languages': languages,
      'availability': availability?.map((slot) => slot.toJson()).toList(),
      'profileImage': profileImage,
      'isOnline': isOnline,
      'education': education?.map((edu) => edu.toJson()).toList(),
      'workExperience': workExperience?.map((exp) => exp.toJson()).toList(),
      'description': description,
      'totalStudents': totalStudents,
      'timezone': timezone,
    });
    return json;
  }

  factory TutorModel.fromJson(Map<String, dynamic> json) {
    return TutorModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      isActive: json['isActive'] as bool? ?? true,
      preferences: json['preferences'] as Map<String, dynamic>?,
      phone: json['phone'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      location: json['location'] != null
          ? LocationModel.fromJson(json['location'])
          : null,
      userSubjects: (json['subjects'] as List<dynamic>?)?.cast<String>(),
      userRating: json['rating'] as double?,
      userTotalSessions: json['totalSessions'] as int?,
      subjects: (json['subjects'] as List<dynamic>).cast<String>(),
      certifications: (json['certifications'] as List<dynamic>).cast<String>(),
      hourlyRate: (json['hourlyRate'] as num).toDouble(),
      bio: json['bio'] as String?,
      experienceYears: json['experienceYears'] as int,
      rating: json['rating'] as double?,
      totalSessions: json['totalSessions'] as int?,
      languages: (json['languages'] as List<dynamic>?)?.cast<String>(),
      availability: (json['availability'] as List<dynamic>?)?.map((slot) =>
          AvailabilitySlot.fromJson(slot)).toList(),
      profileImage: json['profileImage'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
      education: (json['education'] as List<dynamic>?)?.map((edu) =>
          EducationModel.fromJson(edu)).toList(),
      workExperience: (json['workExperience'] as List<dynamic>?)?.map((exp) =>
          WorkExperienceModel.fromJson(exp)).toList(),
      description: json['description'] as String?,
      totalStudents: json['totalStudents'] as int?,
      timezone: json['timezone'] as String?,
    );
  }

  TutorModel copyWith({
    String? id,
    String? email,
    String? name,
    String? avatar,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    Map<String, dynamic>? preferences,
    String? phone,
    String? dateOfBirth,
    LocationModel? location,
    List<String>? userSubjects,
    double? userRating,
    int? userTotalSessions,
    List<String>? subjects,
    List<String>? certifications,
    double? hourlyRate,
    String? bio,
    int? experienceYears,
    double? rating,
    int? totalSessions,
    List<String>? languages,
    List<AvailabilitySlot>? availability,
    String? profileImage,
    bool? isOnline,
    List<EducationModel>? education,
    List<WorkExperienceModel>? workExperience,
    String? description,
    int? totalStudents,
    String? timezone,
  }) {
    return TutorModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      preferences: preferences ?? this.preferences,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      location: location ?? this.location,
      userSubjects: userSubjects ?? this.subjects,
      userRating: userRating ?? this.rating,
      userTotalSessions: userTotalSessions ?? this.totalSessions,
      subjects: subjects ?? this.subjects,
      certifications: certifications ?? this.certifications,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      bio: bio ?? this.bio,
      experienceYears: experienceYears ?? this.experienceYears,
      rating: rating ?? this.rating,
      totalSessions: totalSessions ?? this.totalSessions,
      languages: languages ?? this.languages,
      availability: availability ?? this.availability,
      profileImage: profileImage ?? this.profileImage,
      isOnline: isOnline ?? this.isOnline,
      education: education ?? this.education,
      workExperience: workExperience ?? this.workExperience,
      description: description ?? this.description,
      totalStudents: totalStudents ?? this.totalStudents,
      timezone: timezone ?? this.timezone,
    );
  }

  @override
  List<Object?> get props => [
        ...super.props,
        subjects,
        certifications,
        hourlyRate,
        bio,
        experienceYears,
        rating,
        totalSessions,
        languages,
        availability,
        profileImage,
        isOnline,
        education,
        workExperience,
        description,
        totalStudents,
        timezone,
      ];
}