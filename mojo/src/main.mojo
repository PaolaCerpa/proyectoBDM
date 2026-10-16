"""Punto de entrada del ETL. Se ejecuta desde la raíz del proyecto, con rutas relativas."""

from etl import ejecutar_etl


def main() raises:
    var resumen = ejecutar_etl("resultados/extraccion", "resultados/limpio")
    print(resumen)
