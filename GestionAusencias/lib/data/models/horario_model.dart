import '../../domain/entities/horario.dart';
//primero se convierte los datos en un json  luego se convierte en un objeto en este caso HorarioModel

class HorarioModel extends Horario {
  HorarioModel({
    required super.idHorario,
    required super.texto,
    required super.horarioInicio,
    required super.horarioFin,
    required super.esGuardia,
    required super.recreo,
  });

  factory HorarioModel.fromJson(Map<String, dynamic> json) {
    //factory--> crea un objeto a partir de un json, pero es un constructor especial
    return HorarioModel(
      //clave:valor y luego lo casteamos a int o String o bool
      idHorario: json['id_horario'] as int,
      texto: json['texto'] as String,
      horarioInicio: json['horario_inicio'] as String,
      horarioFin: json['horario_fin'] as String,
      esGuardia: json['es_guardia'] as bool,
      recreo: json['recreo'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    //formato estandar para enviar datos a supabse
    return {
      'id_horario': idHorario,
      'texto': texto,
      'horario_inicio': horarioInicio,
      'horario_fin': horarioFin,
      'es_guardia': esGuardia,
      'recreo': recreo,
    };
  }

  factory HorarioModel.fromEntity(Horario h) {
    //factory en este caso es un puente porque horario no tiene json , pero si horarioModel entonces lo convertimos y asi podemos llamarlo a la supabase
    return HorarioModel(
      idHorario: h.idHorario,
      texto: h.texto,
      horarioInicio: h.horarioInicio,
      horarioFin: h.horarioFin,
      esGuardia: h.esGuardia,
      recreo: h.recreo,
    );
  }
}
