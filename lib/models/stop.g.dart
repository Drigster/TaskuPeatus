// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stop.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StopAdapter extends TypeAdapter<Stop> {
  @override
  final int typeId = 0;

  @override
  Stop read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Stop(
      siriId: (fields[0] as String?) ?? '',
      stopId: (fields[6] as String?) ?? '',
      name: (fields[1] as String?) ?? '',
      lat: (fields[2] as num?)?.toDouble() ?? 0.0,
      lon: (fields[3] as num?)?.toDouble() ?? 0.0,
      isFavorite: (fields[4] as bool?) ?? false,
      transports: (fields[5] as Map?)?.cast<String, String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Stop obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.siriId)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.lat)
      ..writeByte(3)
      ..write(obj.lon)
      ..writeByte(4)
      ..write(obj.isFavorite)
      ..writeByte(5)
      ..write(obj.transports)
      ..writeByte(6)
      ..write(obj.stopId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StopAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
