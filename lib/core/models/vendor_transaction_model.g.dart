// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor_transaction_model.dart';

class VendorTransactionModelAdapter extends TypeAdapter<VendorTransactionModel> {
  @override
  final int typeId = 6;

  @override
  VendorTransactionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VendorTransactionModel()
      ..id = fields[0] as String
      ..vendorId = fields[1] as String
      ..vendorName = fields[2] as String
      ..storeId = fields[3] as String
      ..type = fields[4] as String
      ..timestamp = fields[5] as DateTime
      ..totalAmountPaisa = fields[6] as int
      ..items = (fields[7] as List).cast<VendorOrderItem>()
      ..note = fields[8] as String?;
  }

  @override
  void write(BinaryWriter writer, VendorTransactionModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.vendorId)
      ..writeByte(2)
      ..write(obj.vendorName)
      ..writeByte(3)
      ..write(obj.storeId)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.timestamp)
      ..writeByte(6)
      ..write(obj.totalAmountPaisa)
      ..writeByte(7)
      ..write(obj.items)
      ..writeByte(8)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VendorTransactionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class VendorOrderItemAdapter extends TypeAdapter<VendorOrderItem> {
  @override
  final int typeId = 7;

  @override
  VendorOrderItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VendorOrderItem()
      ..name = fields[0] as String
      ..qty = fields[1] as int
      ..pricePaisa = fields[2] as int
      ..unit = fields[3] as String;
  }

  @override
  void write(BinaryWriter writer, VendorOrderItem obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.qty)
      ..writeByte(2)
      ..write(obj.pricePaisa)
      ..writeByte(3)
      ..write(obj.unit);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VendorOrderItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
