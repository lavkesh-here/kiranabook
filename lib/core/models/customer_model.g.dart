// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_model.dart';

class CustomerModelAdapter extends TypeAdapter<CustomerModel> {
  @override
  final int typeId = 3;

  @override
  CustomerModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CustomerModel()
      ..id = fields[0] as String
      ..storeId = fields[1] as String
      ..name = fields[2] as String
      ..phone = fields[3] as String?
      ..address = fields[4] as String?
      ..createdAt = fields[5] as DateTime;
  }

  @override
  void write(BinaryWriter writer, CustomerModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.storeId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.phone)
      ..writeByte(4)
      ..write(obj.address)
      ..writeByte(5)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
