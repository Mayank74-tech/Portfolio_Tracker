// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'behavior_profile_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BehaviorProfileModelAdapter extends TypeAdapter<BehaviorProfileModel> {
  @override
  final int typeId = 23;

  @override
  BehaviorProfileModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BehaviorProfileModel(
      investingStyle: fields[0] as String,
      statedRiskTolerance: fields[1] as String,
      styleHistory: (fields[2] as List).cast<String>(),
      confidenceScores: (fields[3] as List).cast<double>(),
      actualReturns: (fields[4] as List).cast<double>(),
      decisionTimesSeconds: (fields[5] as List).cast<int>(),
      rebalanceConsideredCount: fields[6] as int,
      rebalanceActedCount: fields[7] as int,
      lastUpdated: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, BehaviorProfileModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.investingStyle)
      ..writeByte(1)
      ..write(obj.statedRiskTolerance)
      ..writeByte(2)
      ..write(obj.styleHistory)
      ..writeByte(3)
      ..write(obj.confidenceScores)
      ..writeByte(4)
      ..write(obj.actualReturns)
      ..writeByte(5)
      ..write(obj.decisionTimesSeconds)
      ..writeByte(6)
      ..write(obj.rebalanceConsideredCount)
      ..writeByte(7)
      ..write(obj.rebalanceActedCount)
      ..writeByte(8)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BehaviorProfileModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
