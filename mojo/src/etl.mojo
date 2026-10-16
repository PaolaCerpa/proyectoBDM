"""Módulo ETL del proyecto BDM.

Responsabilidad de Mojo: leer los registros extraídos de MongoDB (archivos de
texto con columnas separadas por tabulador), validarlos, limpiarlos, comprobar
la integridad referencial y escribir los resultados.
Responsabilidad de Python (fuera de este módulo): extraer de MongoDB, escribir
los archivos de entrada y cargar los archivos limpios a SQLite.
"""

from std.collections import Set
from validacion import validar_persona, validar_articulo, validar_venta, validar_integridad_referencial


def unir(campos: List[String]) -> String:
    """Une los campos de un registro separándolos con tabulador.

    Propósito: reconstruir la línea original tal como llegó del TSV para poder
        registrarla completa en rechazados.tsv cuando el registro no es válido.
    Entradas: campos (List[String]) con los valores de un único registro.
    Salidas: un String con los campos unidos por tabulador, sin salto de línea.
    Regla de validación: no aplica; es una utilidad de formato, no valida datos.
    Manejo de errores: no lanza errores; una lista vacía devuelve un String vacío.
    Evidencia de ejecución: usada en ejecutar_etl (mojo/src/etl.mojo) y cubierta
        indirectamente por mojo/tests/test_etl.mojo.
    """
    var texto = String()
    for i in range(len(campos)):
        if i > 0:
            texto += "\t"
        texto += campos[i]
    return texto


def leer_registros(ruta: String) raises -> List[List[String]]:
    """Lee un archivo de texto y devuelve un registro por línea no vacía.

    Propósito: cargar en memoria los registros extraídos de MongoDB para que el
        ETL los valide, limpie e integre.
    Entradas: ruta del archivo (columnas separadas por tabulador).
    Salidas: lista de registros, cada uno como lista de campos.
    Regla de validación: no valida el contenido; solo separa por tabulador y
        descarta las líneas vacías. La validación la hacen validar_persona,
        validar_articulo y validar_venta.
    Manejo de errores: lanza un error si el archivo no existe o no se puede leer.
    Evidencia de ejecución: usada en ejecutar_etl y probada en
        mojo/tests/test_etl.mojo (escenarios con datos y con archivos vacíos).
    """
    var archivo = open(ruta, "r")
    var contenido = archivo.read()
    archivo.close()
    var registros = List[List[String]]()
    for linea in contenido.split("\n"):
        if linea.byte_length() == 0:
            continue
        var campos = List[String]()
        for parte in linea.split("\t"):
            campos.append(String(parte))
        registros.append(campos^)
    return registros^


def escribir_texto(ruta: String, texto: String) raises:
    """Escribe el texto en el archivo, reemplazando su contenido anterior.

    Propósito: dejar en disco los archivos limpios, el archivo de rechazados y
        el resumen del ETL para que Python los cargue a SQLite y queden como
        evidencia reproducible.
    Entradas: ruta del archivo destino; texto a escribir.
    Salidas: ninguna; el efecto es el archivo escrito (se sobreescribe).
    Regla de validación: no aplica; recibe el texto ya construido por el ETL.
    Manejo de errores: lanza un error si la ruta no es escribible o no existe la
        carpeta destino.
    Evidencia de ejecución: usada en ejecutar_etl para escribir
        personas_limpias.tsv, articulos_limpios.tsv, ventas_limpias.tsv,
        rechazados.tsv y resumen.txt; verificada por mojo/tests/test_etl.mojo.
    """
    var archivo = open(ruta, "w")
    archivo.write(texto)
    archivo.close()


def ejecutar_etl(carpeta_entrada: String, carpeta_salida: String) raises -> String:
    """Ejecuta el ETL completo sobre las tres fuentes.

    Propósito: producir los datos limpios que se cargarán a la base relacional,
        sin eliminar registros en silencio.
    Entradas: carpeta_entrada con personas.tsv, articulos.tsv y ventas.tsv;
        carpeta_salida (debe existir) donde se escriben los resultados.
    Salidas: escribe personas_limpias.tsv, articulos_limpios.tsv,
        ventas_limpias.tsv, rechazados.tsv (fuente, línea, motivo, registro
        original) y resumen.txt; devuelve el texto del resumen.
    Regla de validación: validar_persona, validar_articulo y validar_venta
        sobre cada registro; idArticulo se compara como número (sin ceros a la
        izquierda) y el repetido se rechaza conservando la primera aparición;
        cada venta se acepta solo si su comprador y su artículo se cargaron (validar_integridad_referencial).
    Manejo de errores: un registro inválido no detiene el proceso: se registra
        en rechazados.tsv con su motivo. Un archivo de entrada ausente lanza error.
    Evidencia de ejecución: mojo/tests/test_etl.mojo y mojo/src/main.mojo.
    """
    var personas = leer_registros(carpeta_entrada + "/personas.tsv")
    var articulos = leer_registros(carpeta_entrada + "/articulos.tsv")
    var ventas = leer_registros(carpeta_entrada + "/ventas.tsv")

    var rechazados = String()
    var personas_ok = Set[String]()
    var articulos_ok = Set[String]()
    var salida_personas = String()
    var salida_articulos = String()
    var salida_ventas = String()
    var rech_personas = 0
    var rech_articulos = 0
    var rech_ventas = 0

    for i in range(len(personas)):
        var original = unir(personas[i])
        var motivo = validar_persona(personas[i])
        if motivo.byte_length() > 0:
            rechazados += String("personas\t", i + 1, "\t", motivo, "\t", original, "\n")
            rech_personas += 1
        else:
            var clave = personas[i][0]
            personas_ok.add(clave)
            salida_personas += unir(personas[i]) + "\n"

    for i in range(len(articulos)):
        var original = unir(articulos[i])
        var motivo = validar_articulo(articulos[i])
        var clave = String()
        if motivo.byte_length() == 0:
            # El id se normaliza a número (sin ceros a la izquierda): "0883" y "883"
            # son la misma clave primaria entera en la base relacional.
            clave = String(atol(articulos[i][0]))
            articulos[i][0] = clave
            if clave in articulos_ok:
                motivo = String("idArticulo duplicado (se conserva la primera aparición)")
        if motivo.byte_length() > 0:
            rechazados += String("articulos\t", i + 1, "\t", motivo, "\t", original, "\n")
            rech_articulos += 1
        else:
            articulos_ok.add(clave)
            salida_articulos += unir(articulos[i]) + "\n"

    for i in range(len(ventas)):
        var original = unir(ventas[i])
        var motivo = validar_venta(ventas[i])
        if motivo.byte_length() == 0:
            motivo = validar_integridad_referencial(ventas[i][1], ventas[i][2], personas_ok, articulos_ok)
        if motivo.byte_length() > 0:
            rechazados += String("ventas\t", i + 1, "\t", motivo, "\t", original, "\n")
            rech_ventas += 1
        else:
            salida_ventas += unir(ventas[i]) + "\n"

    var resumen = String(
        "personas: leidas=", len(personas), " validas=", len(personas) - rech_personas,
        " rechazadas=", rech_personas, "\n",
        "articulos: leidas=", len(articulos), " validos=", len(articulos) - rech_articulos,
        " rechazados=", rech_articulos, "\n",
        "ventas: leidas=", len(ventas), " validas=", len(ventas) - rech_ventas,
        " rechazadas=", rech_ventas,
    )

    escribir_texto(carpeta_salida + "/personas_limpias.tsv", salida_personas)
    escribir_texto(carpeta_salida + "/articulos_limpios.tsv", salida_articulos)
    escribir_texto(carpeta_salida + "/ventas_limpias.tsv", salida_ventas)
    escribir_texto(carpeta_salida + "/rechazados.tsv", rechazados)
    escribir_texto(carpeta_salida + "/resumen.txt", resumen)
    return resumen
