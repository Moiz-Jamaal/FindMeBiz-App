import 'cart_item.dart';

class Order {
  final String id;
  final String sellerId;
  final String sellerName;
  final List<CartItem> items;
  final double totalAmount;
  final OrderStatus status;
  final DateTime orderDate;
  final DateTime? deliveryDate;
  final String deliveryAddress;
  final String? trackingNumber;
  final String? notes;

  Order({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.orderDate,
    this.deliveryDate,
    required this.deliveryAddress,
    this.trackingNumber,
    this.notes,
  });

  Order copyWith({
    String? id,
    String? sellerId,
    String? sellerName,
    List<CartItem>? items,
    double? totalAmount,
    OrderStatus? status,
    DateTime? orderDate,
    DateTime? deliveryDate,
    String? deliveryAddress,
    String? trackingNumber,
    String? notes,
  }) {
    return Order(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      orderDate: orderDate ?? this.orderDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'items': items.map((x) => x.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status.index,
      'orderDate': orderDate.toIso8601String(),
      'deliveryDate': deliveryDate?.toIso8601String(),
      'deliveryAddress': deliveryAddress,
      'trackingNumber': trackingNumber,
      'notes': notes,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'],
      sellerId: map['sellerId'],
      sellerName: map['sellerName'],
      items: List<CartItem>.from(map['items']?.map((x) => CartItem.fromMap(x))),
      totalAmount: map['totalAmount']?.toDouble() ?? 0.0,
      status: OrderStatus.values[map['status']],
      orderDate: DateTime.parse(map['orderDate']),
      deliveryDate: map['deliveryDate'] != null ? DateTime.parse(map['deliveryDate']) : null,
      deliveryAddress: map['deliveryAddress'],
      trackingNumber: map['trackingNumber'],
      notes: map['notes'],
    );
  }

  String get statusText => status.name.toUpperCase();
  bool get canCancel => status == OrderStatus.pending || status == OrderStatus.confirmed;
  bool get canTrack => trackingNumber != null && trackingNumber!.isNotEmpty;
}

enum OrderStatus { pending, confirmed, processing, shipped, delivered, cancelled }

extension OrderStatusExtension on OrderStatus {
  String get name => toString().split('.').last;
}
