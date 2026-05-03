// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_model.dart';

class ItemModelAdapter extends TypeAdapter<ItemModel> {
  @override
  final int typeId = 2;

  @override
  ItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ItemModel()
      ..id = fields[0] as String
      ..storeId = fields[1] as String
      ..name = fields[2] as String
      ..nameHindi = fields[3] as String?
      ..pricePaisa = fields[4] as int
      ..stock = fields[5] as int
      ..lowStockAlert = fields[6] as int
      ..unit = fields[7] as String
      ..active = fields[8] as bool
      ..updatedAt = fields[9] as DateTime
      ..mrpPaisa = fields[10] == null ? 0 : fields[10] as int;
  }

  @override
  void write(BinaryWriter writer, ItemModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.storeId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.nameHindi)
      ..writeByte(4)
      ..write(obj.pricePaisa)
      ..writeByte(5)
      ..write(obj.stock)
      ..writeByte(6)
      ..write(obj.lowStockAlert)
      ..writeByte(7)
      ..write(obj.unit)
      ..writeByte(8)
      ..write(obj.active)
      ..writeByte(9)
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.mrpPaisa);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
