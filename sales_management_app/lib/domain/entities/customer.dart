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
      id: json['ID'],
      name: json['Name'],
      address: json['Address'],
      areaId: json['AreaID'],
      categoryId: json['CategoryID'],
      areaName: json['AreaName'],
      categoryName: json['CategoryName'],
    );
  }
}