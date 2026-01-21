import 'package:flutter/material.dart';
import '../../data/models/profesor_model.dart';

class TarjetaProfesor extends StatelessWidget {
  final Profesores profesor;
  const TarjetaProfesor({super.key, required this.profesor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: 8,
      ), //espacio de arriba y de abajo, ahce una sepacion fuera de la tarjeta
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            blurRadius: 10, //difuminado
            offset: const Offset(0, 2), //desplazamiento pero de x y y
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          //lo que se ve al principio de la tarjeta
          backgroundImage: NetworkImage(profesor.foto),
          backgroundColor: Theme.of(
            context,
          ).primaryColor, //color de la tarjeta de fondo mientras carga
        ),
        title: Text(
          profesor.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment
              .start, //alineacion de los textos a la izquierda
          children: [
            const SizedBox(height: 4), //separador invisible
            Text(
              '${profesor.asignatura} • ${profesor.curso}',
            ), //$ es la llave del dato,, para decir que es un variable que tiene que leer, el punto como un separador,
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey.shade400,
        ), //icono que se ve al final de la tarjeta
        //flecha que apunta a la derecha
      ),
    );
  }
}
