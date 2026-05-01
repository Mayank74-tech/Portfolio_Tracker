// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attention_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AttentionLogModelAdapter extends TypeAdapter<AttentionLogModel> {
  @override
  final int typeId = 20;

  @override
  AttentionLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AttentionLogModel(
      symbol: fields[0] as String,
      viewedAt: fields[1] as DateTime,
      durationSeconds: fields[2] as int,
      screenName: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AttentionLogModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.symbol)
      ..writeByte(1)
      ..write(obj.viewedAt)
      ..writeByte(2)
      ..write(obj.durationSeconds)
      ..writeByte(3)
      ..write(obj.screenName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttentionLogModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
