class Customer {
  final int id;
  final String name;
  final String address;
  final int areaId;
  final int categoryId;
  final String? areaName;
  final String? categoryName;

  Customer({
    required this.id,
    required this.name,
    required this.address,
    required this.areaId,
    required this.categoryId,
    this.areaName,
    this.categoryName,
  });

  Map<String, dynamic> toJson() {
    return {
      'Name': name,
      'Address': address,
      'AreaID': areaId,
      'CategoryID': categoryId,
    };
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['ID'] ?? json['id'],
      name: json['Name'] ?? json['name'],
      address: json['Address'] ?? json['address'],
      areaId: json['AreaID'] ?? json['areaId'],
      categoryId: json['CategoryID'] ?? json['categoryId'],
      areaName: json['AreaName'] ?? json['areaName'],
      categoryName: json['CategoryName'] ?? json['categoryName'],
    );
  }

  //  copyWith method
  Customer copyWith({
    int? id,
    String? name,
    String? address,
    int? areaId,
    int? categoryId,
    String? areaName,
    String? categoryName,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      areaId: areaId ?? this.areaId,
      categoryId: categoryId ?? this.categoryId,
      areaName: areaName ?? this.areaName,
      categoryName: categoryName ?? this.categoryName,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is Customer &&
        other.id == id &&
        other.name == name &&
        other.address == address &&
        other.areaId == areaId &&
        other.categoryId == categoryId &&
        other.areaName == areaName &&
        other.categoryName == categoryName;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        address.hashCode ^
        areaId.hashCode ^
        categoryId.hashCode ^
        areaName.hashCode ^
        categoryName.hashCode;
  }
}