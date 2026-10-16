"""Módulo de validación del proyecto BDM.

Cada función recibe el registro como lista de campos (en el orden del JSON) y
devuelve el motivo de rechazo. Un String vacío significa registro válido.
Si un campo se puede limpiar, la función lo corrige en la propia lista; un
campo que pasa a NULL queda como String vacío.
Orden de campos:
    persona : numeroDocumento, nombres, primerApellido, segundoApellido,
              fechaNacimiento, telefono, direccion, email
    artículo: idArticulo, nombreArticulo, precioArticulo, cantidadArticulo
    venta   : idVenta, idComprador, idArticulo, cantidadProductos, precioTotal
"""

from std.collections import Set
from limpieza import es_solo_digitos, limpiar_valor_numerico


def es_numero_positivo(valor: String) -> Bool:
    """Indica si el valor es un número decimal mayor que cero.

    Propósito: validar precios sin depender de la conversión a decimal.
    Entradas: valor (String).
    Salidas: True si solo contiene dígitos y a lo sumo un punto, con al menos
        un dígito distinto de cero; False en cualquier otro caso.
    Regla de validación: solo dígitos y a lo sumo un punto decimal, con valor > 0.
    Manejo de errores: no lanza errores; vacío o con símbolos devuelve False.
    Evidencia de ejecución: mojo/tests/test_validacion.mojo.
    """
    var hay_digito = False
    var hay_distinto_de_cero = False
    var puntos = 0
    for c in valor.codepoint_slices():
        var s = String(c)
        if s.is_ascii_digit():
            hay_digito = True
            if s != "0":
                hay_distinto_de_cero = True
        elif s == ".":
            puntos += 1
            if puntos > 1:
                return False
        else:
            return False
    return hay_digito and hay_distinto_de_cero


def validar_persona(mut campos: List[String]) -> String:
    """Valida un registro de PERSONAS.

    Propósito: decidir si la persona puede cargarse a la base relacional.
    Entradas: campos (8 valores); se modifica en el lugar.
    Salidas: "" si es válida; si no, el motivo de rechazo.
    Regla de validación: numeroDocumento (clave primaria) debe ser solo dígitos
        y no se reconstruye; telefono dañado pasa a NULL y la persona se conserva.
    Manejo de errores: no lanza errores; una lista con otro número de campos
        se rechaza por estructura.
    Evidencia de ejecución: mojo/tests/test_validacion.mojo.
    """
    if len(campos) != 8:
        return "estructura: se esperaban 8 campos"
    if not es_solo_digitos(campos[0]):
        return "numeroDocumento inválido"
    if not es_solo_digitos(campos[5]):
        campos[5] = String("")
    return ""


def validar_articulo(mut campos: List[String]) -> String:
    """Valida un registro de ARTICULOS.

    Propósito: decidir si el artículo puede cargarse a la base relacional.
    Entradas: campos (4 valores); se modifica en el lugar.
    Salidas: "" si es válido; si no, el motivo de rechazo.
    Regla de validación: idArticulo se recupera quitando los caracteres no
        numéricos y se rechaza si no queda ningún dígito; precioArticulo debe
        ser un número mayor que cero; cantidadArticulo dañada pasa a NULL.
    Manejo de errores: no lanza errores; otro número de campos se rechaza por
        estructura.
    Evidencia de ejecución: mojo/tests/test_validacion.mojo.
    """
    if len(campos) != 4:
        return "estructura: se esperaban 4 campos"
    var id_limpio = limpiar_valor_numerico(campos[0])
    if id_limpio.byte_length() == 0:
        return "idArticulo no recuperable"
    campos[0] = id_limpio
    if not es_numero_positivo(campos[2]):
        return "precioArticulo inválido"
    if not es_solo_digitos(campos[3]):
        campos[3] = String("")
    return ""


def validar_venta(mut campos: List[String]) -> String:
    """Valida un registro de VENTAS.

    Propósito: decidir si la venta puede cargarse a la base relacional.
    Entradas: campos (5 valores); se modifica en el lugar.
    Salidas: "" si es válida; si no, el motivo de rechazo.
    Regla de validación: idVenta, idComprador e idArticulo deben ser solo
        dígitos (idComprador es llave foránea y no se reconstruye);
        cantidadProductos se recupera quitando caracteres no numéricos y debe
        quedar entre 1 y 10; precioTotal debe ser un número mayor que cero.
    Manejo de errores: no lanza errores; otro número de campos se rechaza por
        estructura.
    Evidencia de ejecución: mojo/tests/test_validacion.mojo.
    """
    if len(campos) != 5:
        return "estructura: se esperaban 5 campos"
    if not es_solo_digitos(campos[0]):
        return "idVenta inválido"
    if not es_solo_digitos(campos[1]):
        return "idComprador inválido"
    if not es_solo_digitos(campos[2]):
        return "idArticulo inválido"
    var cantidad = limpiar_valor_numerico(campos[3])
    var en_rango = (cantidad.byte_length() == 1 and cantidad != "0") or cantidad == "10"
    if not en_rango:
        return "cantidadProductos no recuperable o fuera de rango 1-10"
    campos[3] = cantidad
    if not es_numero_positivo(campos[4]):
        return "precioTotal inválido"
    return ""

def validar_integridad_referencial(
    id_comprador: String,
    id_articulo: String,
    personas: Set[String],
    articulos: Set[String],
) -> String:
    """Verifica que una venta apunte a una persona y a un artículo existentes.

    Propósito: impedir que lleguen a la base relacional ventas huérfanas, es
        decir, con llaves foráneas que no tienen registro asociado.
    Entradas: id_comprador e id_articulo de la venta (ya validados como solo
        dígitos); personas y articulos, conjuntos con los ids que SÍ se cargaron.
    Salidas: "" si ambas referencias existen; si no, el motivo de rechazo.
    Regla de validación: id_comprador debe estar en personas e id_articulo en
        articulos. Se comprueba primero el comprador.
    Manejo de errores: no lanza errores; un id vacío o desconocido se rechaza
        con su motivo y la venta se guarda en rechazados, no se elimina en silencio.
    Evidencia de ejecución: mojo/tests/test_integridad.mojo.
    """
    if not (id_comprador in personas):
        return "idComprador sin persona asociada"
    if not (id_articulo in articulos):
        return "idArticulo sin artículo asociado"
    return ""
