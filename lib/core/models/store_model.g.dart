// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store_model.dart';

class StoreModelAdapter extends TypeAdapter<StoreModel> {
  @override
  final int typeId = 4;

  @override
  StoreModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StoreModel()
      ..id = fields[0] as String
      ..name = fields[1] as String
      ..ownerName = fields[2] as String
      ..phone = fields[3] as String
      ..language = fields[4] as String
      ..createdAt = fields[5] as DateTime
      ..isSetupDone = fields[6] as bool;
  }

  @override
  void write(BinaryWriter writer, StoreModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.ownerName)
      ..writeByte(3)
      ..write(obj.phone)
      ..writeByte(4)
      ..write(obj.language)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.isSetupDone);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoreModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
