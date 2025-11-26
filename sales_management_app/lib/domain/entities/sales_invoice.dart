class SalesInvoice {
  final int txnNo;
  final DateTime txnDate;
  final int customerId;
  final String address;
  final double totalQty;
  final double totalAmount;
  final List<SalesDetail> items;

  SalesInvoice({
    required this.txnNo,
    required this.txnDate,
    required this.customerId,
    required this.address,
    required this.totalQty,
    required this.totalAmount,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'CustomerId': customerId,
      'Address': address,
      'TotalQty': totalQty,
      'TotalAmount': totalAmount,
      'Items': items.map((item) => item.toJson()).toList(),
    };
  }

  factory SalesInvoice.fromJson(Map<String, dynamic> json) {
    // Ultra-safe double parsing
    double safeParse(dynamic value) {
      try {
        if (value == null) return 0.0;
        if (value is double) return value;
        if (value is int) return value.toDouble();
        if (value is String) {
          // Remove any non-numeric characters except decimal point
          String cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
          return double.tryParse(cleaned) ?? 0.0;
        }
        return double.tryParse(value.toString()) ?? 0.0;
      } catch (e) {
        print('❌ Error parsing double in SalesInvoice: $value, error: $e');
        return 0.0;
      }
    }

    return SalesInvoice(
      txnNo: (json['TxnNo'] ?? json['txnNo'] ?? 0).toInt(),
      txnDate: DateTime.parse(json['txnDate'] ?? DateTime.now().toString()),
      customerId: (json['CustomerId'] ?? json['customerId'] ?? 0).toInt(),
      address: (json['Address'] ?? json['address'] ?? '').toString(),
      totalQty: safeParse(json['TotalQty'] ?? json['totalQty']),
      totalAmount: safeParse(json['TotalAmount'] ?? json['totalAmount']),
      items: (json['Items'] as List<dynamic>? ?? [])
          .map((item) => SalesDetail.fromJson(item))
          .toList(),
    );
  }
}

class SalesDetail {
  final int id;
  final int txnNo;
  final int sno;
  final int productId;
  final double quantity;
  final double rate;
  final double discount;
  final double amount;
  final String? productName;

  SalesDetail({
    required this.id,
    required this.txnNo,
    required this.sno,
    required this.productId,
    required this.quantity,
    required this.rate,
    required this.discount,
    required this.amount,
    this.productName,
  });

  Map<String, dynamic> toJson() {
    return {
      'ProductID': productId,
      'Quantity': quantity,
      'Rate': rate,
      'Discount': discount,
      'Amount': amount,
    };
  }

  factory SalesDetail.fromJson(Map<String, dynamic> json) {
    // Ultra-safe double parsing
    double safeParse(dynamic value) {
      try {
        if (value == null) return 0.0;
        if (value is double) return value;
        if (value is int) return value.toDouble();
        if (value is String) {
          // Remove any non-numeric characters except decimal point
          String cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
          return double.tryParse(cleaned) ?? 0.0;
        }
        return double.tryParse(value.toString()) ?? 0.0;
      } catch (e) {
        print('❌ Error parsing double in SalesDetail: $value, error: $e');
        return 0.0;
      }
    }

    return SalesDetail(
      id: (json['ID'] ?? json['id'] ?? 0).toInt(),
      txnNo: (json['TxnNo'] ?? json['txnNo'] ?? 0).toInt(),
      sno: (json['Sno'] ?? json['sno'] ?? 0).toInt(),
      productId: (json['ProductID'] ?? json['productId'] ?? 0).toInt(),
      quantity: safeParse(json['Quantity'] ?? json['quantity']),
      rate: safeParse(json['Rate'] ?? json['rate']),
      discount: safeParse(json['Discount'] ?? json['discount']),
      amount: safeParse(json['Amount'] ?? json['amount']),
      productName: json['ProductName'] ?? json['productName'],
    );
  }

  SalesDetail copyWith({
    int? id,
    int? txnNo,
    int? sno,
    int? productId,
    double? quantity,
    double? rate,
    double? discount,
    double? amount,
    String? productName,
  }) {
    return SalesDetail(
      id: id ?? this.id,
      txnNo: txnNo ?? this.txnNo,
      sno: sno ?? this.sno,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      rate: rate ?? this.rate,
      discount: discount ?? this.discount,
      amount: amount ?? this.amount,
      productName: productName ?? this.productName,
    );
  }
}

class InvoiceItem {
  final int productId;
  final String productName;
  final double rate;
  double quantity;
  double discount;
  double get amount => (quantity * rate) - discount;

  InvoiceItem({
    required this.productId,
    required this.productName,
    required this.rate,
    this.quantity = 1,
    this.discount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'rate': rate,
      'quantity': quantity,
      'discount': discount,
      'amount': amount,
    };
  }
}