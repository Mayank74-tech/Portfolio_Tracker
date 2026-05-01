// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'belief_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BeliefLogModelAdapter extends TypeAdapter<BeliefLogModel> {
  @override
  final int typeId = 21;

  @override
  BeliefLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BeliefLogModel(
      question: fields[0] as String,
      userBelief: fields[1] as String,
      actualAnswer: fields[2] as String,
      wasCorrect: fields[3] as bool,
      recordedAt: fields[4] as DateTime,
      explanation: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, BeliefLogModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.question)
      ..writeByte(1)
      ..write(obj.userBelief)
      ..writeByte(2)
      ..write(obj.actualAnswer)
      ..writeByte(3)
      ..write(obj.wasCorrect)
      ..writeByte(4)
      ..write(obj.recordedAt)
      ..writeByte(5)
      ..write(obj.explanation);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BeliefLogModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
