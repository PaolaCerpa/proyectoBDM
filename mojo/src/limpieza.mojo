"""Módulo de limpieza del proyecto BDM.

Responsabilidad de Mojo: limpiar valores numéricos dañados antes de validarlos.
Regla de negocio (sección 5.1): solo se recuperan los campos donde el daño
AGREGA caracteres (cantidadProductos, idArticulo). Los identificadores donde el
daño REEMPLAZA dígitos (documento, teléfono, idComprador) no se reconstruyen.
"""


def es_solo_digitos(valor: String) -> Bool:
    """Indica si el valor es un entero sin signo escrito solo con dígitos.

    Propósito: aplicar la regla de validación estricta de los identificadores.
    Entradas: valor (String), el texto tal como llegó de MongoDB.
    Salidas: True si tiene al menos un carácter y todos son dígitos 0-9; False
        en cualquier otro caso (vacío, letras, símbolos, espacios o signo).
    Regla de validación: expresión equivalente a ^[0-9]+$.
    Manejo de errores: no lanza errores; un valor vacío devuelve False.
    Evidencia de ejecución: mojo/tests/test_limpieza.mojo.
    """
    return valor.is_ascii_digit()


def limpiar_valor_numerico(valor: String) -> String:
    """Conserva únicamente los dígitos de un valor dañado.

    Propósito: recuperar valores como "2x" o "10K" donde el ruido se agregó
        al número original.
    Entradas: valor (String), el texto tal como llegó de MongoDB.
    Salidas: String con solo los dígitos del valor, en su orden original.
        Un String vacío significa que el valor NO es recuperable.
    Regla de validación: se conservan los caracteres 0-9 y se descarta el resto.
        El llamador debe tratar el resultado vacío como dato no recuperable.
    Manejo de errores: no lanza errores. Un valor vacío o sin dígitos devuelve
        un String vacío, y el módulo de validación decide qué hacer con él
        (rechazar el registro o guardar NULL).
    Evidencia de ejecución: mojo/tests/test_limpieza.mojo.
    """
    var limpio = String()
    for c in valor.codepoint_slices():
        if String(c).is_ascii_digit():
            limpio += c
    return limpio
