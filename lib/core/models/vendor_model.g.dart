// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor_model.dart';

class VendorModelAdapter extends TypeAdapter<VendorModel> {
  @override
  final int typeId = 5;

  @override
  VendorModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VendorModel()
      ..id = fields[0] as String
      ..storeId = fields[1] as String
      ..name = fields[2] as String
      ..phone = fields[3] as String?
      ..bankName = fields[4] as String?
      ..accountNumber = fields[5] as String?
      ..upiId = fields[6] as String?
      ..address = fields[7] as String?
      ..createdAt = fields[8] as DateTime;
  }

  @override
  void write(BinaryWriter writer, VendorModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.storeId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.phone)
      ..writeByte(4)
      ..write(obj.bankName)
      ..writeByte(5)
      ..write(obj.accountNumber)
      ..writeByte(6)
      ..write(obj.upiId)
      ..writeByte(7)
      ..write(obj.address)
      ..writeByte(8)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VendorModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
