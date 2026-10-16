from std.testing import assert_equal, assert_true
from etl import ejecutar_etl


def leer(ruta: String) raises -> String:
    var archivo = open(ruta, "r")
    var contenido = archivo.read()
    archivo.close()
    return contenido


def main() raises:
    var base = "resultados/prueba_etl"

    # Escenario 1: datos con registros válidos, inválidos y duplicados
    var resumen = ejecutar_etl(base + "/entrada", base + "/salida")
    assert_equal(
        resumen,
        String("personas: leidas=3 validas=2 rechazadas=1\narticulos: leidas=4 validos=2 rechazados=2\nventas: leidas=5 validas=2 rechazadas=3"),
    )
    assert_equal(
        leer(base + "/salida/personas_limpias.tsv"),
        String("190252420\tAaron\tPalmer\tKhan\t2016-05-24\t7546027921\tCalle 1\ta@b.com\n731794571\tLuz\tGomez\tRuiz\t1990-01-01\t\tCalle 3\tc@b.com\n"),
    )
    assert_equal(
        leer(base + "/salida/articulos_limpios.tsv"),
        String("358\tIntel i9\t301.26\t35\n847\tKingston\t280.17\t\n"),
    )
    assert_equal(
        leer(base + "/salida/ventas_limpias.tsv"),
        String("1\t731794571\t847\t2\t202.14\n2\t190252420\t358\t4\t877.25\n"),
    )

    # Escenario 2: archivos de entrada vacíos
    var resumen_vacio = ejecutar_etl(base + "/entrada_vacia", base + "/salida_vacia")
    assert_equal(
        resumen_vacio,
        String("personas: leidas=0 validas=0 rechazadas=0\narticulos: leidas=0 validos=0 rechazados=0\nventas: leidas=0 validas=0 rechazadas=0"),
    )

    # Escenario 3: todos los registros son válidos, no hay rechazados
    var resumen_ok = ejecutar_etl(base + "/entrada_valida", base + "/salida_valida")
    assert_equal(
        resumen_ok,
        String("personas: leidas=1 validas=1 rechazadas=0\narticulos: leidas=1 validos=1 rechazados=0\nventas: leidas=1 validas=1 rechazadas=0"),
    )
    assert_equal(leer(base + "/salida_valida/rechazados.tsv"), String(""))

    # Escenario 4: carpeta de entrada inexistente, debe lanzar error
    var lanzo_error = False
    try:
        _ = ejecutar_etl(base + "/no_existe", base + "/salida")
    except:
        lanzo_error = True
    assert_true(lanzo_error)

    # Escenario 5: ceros a la izquierda; 0358 duplica a 358 y 0917 se normaliza a 917
    var resumen_ceros = ejecutar_etl(base + "/entrada_ceros", base + "/salida_ceros")
    assert_equal(
        resumen_ceros,
        String("personas: leidas=1 validas=1 rechazadas=0\narticulos: leidas=3 validos=2 rechazados=1\nventas: leidas=1 validas=1 rechazadas=0"),
    )
    assert_equal(
        leer(base + "/salida_ceros/articulos_limpios.tsv"),
        String("358\tIntel i9\t301.26\t35\n917\tMouse\t20.5\t5\n"),
    )
    assert_equal(
        leer(base + "/salida_ceros/rechazados.tsv"),
        String("articulos\t2\tidArticulo duplicado (se conserva la primera aparición)\t0358\tIntel i9 con cero\t10.5\t7\n"),
    )

    print("test_etl: todos los escenarios OK")
