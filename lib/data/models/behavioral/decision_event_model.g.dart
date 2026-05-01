// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'decision_event_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DecisionEventModelAdapter extends TypeAdapter<DecisionEventModel> {
  @override
  final int typeId = 22;

  @override
  DecisionEventModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DecisionEventModel(
      id: fields[0] as String,
      symbol: fields[1] as String,
      action: fields[2] as String,
      timestamp: fields[3] as DateTime,
      portfolioValueAtTime: fields[4] as double,
      stockPriceAtTime: fields[5] as double,
      secondsSinceLastView: fields[6] as int,
      context: (fields[7] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, DecisionEventModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.symbol)
      ..writeByte(2)
      ..write(obj.action)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.portfolioValueAtTime)
      ..writeByte(5)
      ..write(obj.stockPriceAtTime)
      ..writeByte(6)
      ..write(obj.secondsSinceLastView)
      ..writeByte(7)
      ..write(obj.context);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DecisionEventModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
