class DateUtilsCustom {
  static List<DateTime> generarSemana(DateTime fechaEnfoque) {
    int diaActual = fechaEnfoque.weekday;
    DateTime lunes = fechaEnfoque.subtract(Duration(days: diaActual - 1));
    return List.generate(7, (index) => lunes.add(Duration(days: index)));
    //index es un contandor para las vueltas que calcula desde 0 al 6, cuántos días sumar a la fecha del "Lunes" para obtener el resto de la semana.
  }

  // NUEVA FUNCIÓN: Calcula el número de semana del mes
  static int numeroSemanaDelMes(DateTime fecha) {
    // Buscamos el primer día del mes
    DateTime primerDiaMes = DateTime(fecha.year, fecha.month, 1);
    // Calculamos la diferencia de días y dividimos por 7
    int diaDelMes = fecha.day;
    int desfasePrimerDia = primerDiaMes.weekday - 1;
    return ((diaDelMes + desfasePrimerDia) / 7).ceil(); //ceil-->redondea
  }
}
