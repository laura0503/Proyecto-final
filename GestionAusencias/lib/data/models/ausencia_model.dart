import '../../domain/entities/ausencia.dart';

class AusenciaModel extends Ausencia {
  const AusenciaModel({
    super.id,
    required super.profesorId,
    required super.fecha,
    required super.fechaInicio,
    super.fechaFin,
    required super.idHorario,
    super.observaciones,
    super.tipo,
    super.tipoDetalle = TipoAusencia.ausenciaPuntual,
    super.esDiaCompleto = false,
  });

  factory AusenciaModel.fromJson(Map<String, dynamic> json) {
    return AusenciaModel(
      id: json['id_ausencia'],
      profesorId: json['id_profesor_ausente']?.toString() ?? '',
      fecha: DateTime.parse(json['fecha']),
      fechaInicio: json['fecha_inicio'] != null 
          ? DateTime.parse(json['fecha_inicio']) 
          : DateTime.parse(json['fecha']),
      fechaFin: json['fecha_fin'] != null ? DateTime.parse(json['fecha_fin']) : null,
      idHorario: json['id_horario_sesion'],
      observaciones: json['observaciones'],
      tipo: 'FALTA',
      esDiaCompleto: json['es_dia_completo'] ?? false,
      tipoDetalle: _mapTipoFromString(json['tipo_detalle']),
    );
  }

  static TipoAusencia _mapTipoFromString(String? type) {
    switch (type) {
      case 'BAJA_MEDICA': return TipoAusencia.bajaMedica;
      case 'VACACIONES': return TipoAusencia.vacaciones;
      case 'DIAS_PERSONALES': return TipoAusencia.diasPersonales;
      case 'FORMACION': return TipoAusencia.formacion;
      case 'INDEFINIDA': return TipoAusencia.ausenciaIndefinida;
      default: return TipoAusencia.ausenciaPuntual;
    }
  }

  static String _mapTipoToString(TipoAusencia type) {
    switch (type) {
      case TipoAusencia.bajaMedica: return 'BAJA_MEDICA';
      case TipoAusencia.vacaciones: return 'VACACIONES';
      case TipoAusencia.diasPersonales: return 'DIAS_PERSONALES';
      case TipoAusencia.formacion: return 'FORMACION';
      case TipoAusencia.ausenciaIndefinida: return 'INDEFINIDA';
      case TipoAusencia.ausenciaPuntual: return 'PUNTUAL';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id_profesor_ausente': int.tryParse(profesorId) ?? 0,
      'id_horario_sesion': idHorario,
      'fecha': fecha.toIso8601String().substring(0, 10),
      'fecha_inicio': fechaInicio.toIso8601String().substring(0, 10),
      if (fechaFin != null) 'fecha_fin': fechaFin!.toIso8601String().substring(0, 10),
      'observaciones': observaciones,
      'tipo_detalle': _mapTipoToString(tipoDetalle),
      'es_dia_completo': esDiaCompleto,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory AusenciaModel.fromEntity(Ausencia ausencia) {
    return AusenciaModel(
      id: ausencia.id,
      profesorId: ausencia.profesorId,
      fecha: ausencia.fecha,
      fechaInicio: ausencia.fechaInicio,
      fechaFin: ausencia.fechaFin,
      idHorario: ausencia.idHorario,
      observaciones: ausencia.observaciones,
      tipo: ausencia.tipo,
      tipoDetalle: ausencia.tipoDetalle,
      esDiaCompleto: ausencia.esDiaCompleto,
    );
  }
}
