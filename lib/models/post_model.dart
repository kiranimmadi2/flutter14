import 'package:cloud_firestore/cloud_firestore.dart';

enum PostCategory {
  dating,
  marketplace,
  jobs,
  lostFound,
  services,
  community,
  friendship,
  housing,
  transportation,
  events,
  other
}

enum PostIntent {
  selling,
  buying,
  offering,
  seeking,
  lost,
  found,
  hiring,
  jobSeeking,
  renting,
  rentSeeking,
  giving,
  requesting,
  meetup,
  dating,
  friendship,
  other
}

class PostModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final PostCategory category;
  final PostIntent? intent;
  final List<String>? images;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isActive;
  final List<double>? embedding;
  final List<String>? keywords;
  final double? similarityScore;
  final String? location;
  final double? latitude;
  final double? longitude;
  final double? price;
  final double? priceMin;
  final double? priceMax;
  final String? currency;
  final int viewCount;
  final List<String> matchedUserIds;
  final Map<String, dynamic>? clarificationAnswers;
  final String? gender;
  final String? ageRange;
  final String? condition;
  final String? brand;

  PostModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    this.intent,
    this.images,
    this.metadata,
    required this.createdAt,
    this.expiresAt,
    this.isActive = true,
    this.embedding,
    this.keywords,
    this.similarityScore,
    this.location,
    this.latitude,
    this.longitude,
    this.price,
    this.priceMin,
    this.priceMax,
    this.currency,
    this.viewCount = 0,
    this.matchedUserIds = const [],
    this.clarificationAnswers,
    this.gender,
    this.ageRange,
    this.condition,
    this.brand,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: PostCategory.values.firstWhere(
        (e) => e.toString().split('.').last == data['category'],
        orElse: () => PostCategory.other,
      ),
      intent: data['intent'] != null 
          ? PostIntent.values.firstWhere(
              (e) => e.toString().split('.').last == data['intent'],
              orElse: () => PostIntent.other,
            )
          : null,
      images: data['images'] != null ? List<String>.from(data['images']) : null,
      metadata: data['metadata'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: data['expiresAt'] != null 
          ? (data['expiresAt'] as Timestamp).toDate() 
          : null,
      isActive: data['isActive'] ?? true,
      embedding: data['embedding'] != null 
          ? List<double>.from(data['embedding']) 
          : null,
      keywords: data['keywords'] != null
          ? List<String>.from(data['keywords'])
          : null,
      similarityScore: data['similarityScore']?.toDouble(),
      location: data['location'],
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      price: data['price']?.toDouble(),
      priceMin: data['priceMin']?.toDouble(),
      priceMax: data['priceMax']?.toDouble(),
      currency: data['currency'],
      viewCount: data['viewCount'] ?? 0,
      matchedUserIds: data['matchedUserIds'] != null 
          ? List<String>.from(data['matchedUserIds']) 
          : [],
      clarificationAnswers: data['clarificationAnswers'],
      gender: data['gender'],
      ageRange: data['ageRange'],
      condition: data['condition'],
      brand: data['brand'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'category': category.toString().split('.').last,
      'intent': intent?.toString().split('.').last,
      'images': images,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'isActive': isActive,
      'embedding': embedding,
      'keywords': keywords,
      'similarityScore': similarityScore,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'price': price,
      'priceMin': priceMin,
      'priceMax': priceMax,
      'currency': currency,
      'viewCount': viewCount,
      'matchedUserIds': matchedUserIds,
      'clarificationAnswers': clarificationAnswers,
      'gender': gender,
      'ageRange': ageRange,
      'condition': condition,
      'brand': brand,
    };
  }

  String get categoryDisplay {
    switch (category) {
      case PostCategory.dating:
        return 'Dating';
      case PostCategory.marketplace:
        return 'Marketplace';
      case PostCategory.jobs:
        return 'Jobs';
      case PostCategory.lostFound:
        return 'Lost & Found';
      case PostCategory.services:
        return 'Services';
      case PostCategory.community:
        return 'Community';
      case PostCategory.friendship:
        return 'Friendship';
      case PostCategory.housing:
        return 'Housing';
      case PostCategory.transportation:
        return 'Transportation';
      case PostCategory.events:
        return 'Events';
      default:
        return 'Other';
    }
  }
  
  String get intentDisplay {
    if (intent == null) return '';
    switch (intent!) {
      case PostIntent.selling:
        return 'Selling';
      case PostIntent.buying:
        return 'Looking to Buy';
      case PostIntent.offering:
        return 'Offering';
      case PostIntent.seeking:
        return 'Seeking';
      case PostIntent.lost:
        return 'Lost';
      case PostIntent.found:
        return 'Found';
      case PostIntent.hiring:
        return 'Hiring';
      case PostIntent.jobSeeking:
        return 'Looking for Job';
      case PostIntent.renting:
        return 'For Rent';
      case PostIntent.rentSeeking:
        return 'Looking to Rent';
      case PostIntent.giving:
        return 'Giving Away';
      case PostIntent.requesting:
        return 'Requesting';
      case PostIntent.meetup:
        return 'Meetup';
      case PostIntent.dating:
        return 'Dating';
      case PostIntent.friendship:
        return 'Friendship';
      default:
        return '';
    }
  }
  
  bool matchesIntent(PostIntent otherIntent) {
    if (intent == null) return false;
    
    // Define matching rules
    switch (intent!) {
      case PostIntent.selling:
        return otherIntent == PostIntent.buying;
      case PostIntent.buying:
        return otherIntent == PostIntent.selling;
      case PostIntent.offering:
        return otherIntent == PostIntent.seeking;
      case PostIntent.seeking:
        return otherIntent == PostIntent.offering;
      case PostIntent.lost:
        return otherIntent == PostIntent.found;
      case PostIntent.found:
        return otherIntent == PostIntent.lost;
      case PostIntent.hiring:
        return otherIntent == PostIntent.jobSeeking;
      case PostIntent.jobSeeking:
        return otherIntent == PostIntent.hiring;
      case PostIntent.renting:
        return otherIntent == PostIntent.rentSeeking;
      case PostIntent.rentSeeking:
        return otherIntent == PostIntent.renting;
      case PostIntent.giving:
        return otherIntent == PostIntent.requesting;
      case PostIntent.requesting:
        return otherIntent == PostIntent.giving;
      case PostIntent.meetup:
      case PostIntent.dating:
      case PostIntent.friendship:
        return otherIntent == intent;
      default:
        return false;
    }
  }
  
  bool matchesPrice(PostModel other) {
    // If neither has price info, consider it a match
    if (price == null && other.price == null && 
        priceMin == null && other.priceMin == null &&
        priceMax == null && other.priceMax == null) {
      return true;
    }
    
    // Check if price ranges overlap
    if (intent == PostIntent.selling && other.intent == PostIntent.buying) {
      // Seller's price should be within buyer's range
      if (price != null && other.priceMax != null) {
        return price! <= other.priceMax!;
      }
      if (price != null && other.priceMin != null && other.priceMax != null) {
        return price! >= other.priceMin! && price! <= other.priceMax!;
      }
    }
    
    if (intent == PostIntent.buying && other.intent == PostIntent.selling) {
      // Buyer's range should include seller's price
      if (other.price != null && priceMax != null) {
        return other.price! <= priceMax!;
      }
      if (other.price != null && priceMin != null && priceMax != null) {
        return other.price! >= priceMin! && other.price! <= priceMax!;
      }
    }
    
    return true;
  }
}