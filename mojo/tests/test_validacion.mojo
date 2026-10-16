from std.testing import assert_equal, assert_true, assert_false
from validacion import validar_persona, validar_articulo, validar_venta, es_numero_positivo


def lista(*valores: String) -> List[String]:
    """Construye una List[String] a partir de los valores recibidos."""
    var resultado = List[String]()
    for i in range(len(valores)):
        resultado.append(valores[i])
    return resultado^


def main() raises:
    # es_numero_positivo: válido, inválido, vacío
    assert_true(es_numero_positivo("301.26"))
    assert_false(es_numero_positivo("0"))
    assert_false(es_numero_positivo(""))

    # validar_persona
    var p1 = lista("190252420", "Aaron", "Palmer", "Khan", "2016-05-24", "7546027921", "Calle 1", "a@b.com")
    assert_equal(validar_persona(p1), String(""))                       # válida
    assert_equal(p1[5], String("7546027921"))
    var p2 = lista("190252420", "Aaron", "Palmer", "Khan", "2016-05-24", "422$9Aq9@1", "Calle 1", "a@b.com")
    assert_equal(validar_persona(p2), String(""))                       # teléfono dañado -> NULL
    assert_equal(p2[5], String(""))
    var p3 = lista("@10@93@!65", "Samuel", "Roberts", "Sweeney", "1938-05-30", "7546027921", "Calle 1", "a@b.com")
    assert_equal(validar_persona(p3), String("numeroDocumento inválido"))   # no recuperable
    var p4 = List[String]()
    assert_equal(validar_persona(p4), String("estructura: se esperaban 8 campos"))   # vacío

    # validar_articulo
    var a1 = lista("358", "Intel i9", "301.26", "35")
    assert_equal(validar_articulo(a1), String(""))                      # válido
    assert_equal(a1[0], String("358"))
    var a2 = lista("T474", "SeaSonic Focus Plus", "237.64", "m18")
    assert_equal(validar_articulo(a2), String(""))                      # id recuperado, cantidad -> NULL
    assert_equal(a2[0], String("474"))
    assert_equal(a2[3], String(""))
    var a3 = lista("@@@", "X", "10.5", "3")
    assert_equal(validar_articulo(a3), String("idArticulo no recuperable"))
    var a4 = lista("358", "X", "0", "3")
    assert_equal(validar_articulo(a4), String("precioArticulo inválido"))
    var a5 = List[String]()
    assert_equal(validar_articulo(a5), String("estructura: se esperaban 4 campos"))   # vacío

    # validar_venta
    var v1 = lista("2", "731794571", "847", "4", "877.25")
    assert_equal(validar_venta(v1), String(""))                         # válida
    var v2 = lista("1", "731794571", "2358", "2x", "202.14")
    assert_equal(validar_venta(v2), String(""))                         # cantidad recuperada
    assert_equal(v2[3], String("2"))
    var v3 = lista("1", "731794571", "2358", "10K", "202.14")
    assert_equal(validar_venta(v3), String(""))
    assert_equal(v3[3], String("10"))
    var v4 = lista("1", "q61@A!213A", "2358", "2", "202.14")
    assert_equal(validar_venta(v4), String("idComprador inválido"))     # no recuperable
    var v5 = lista("1", "731794571", "2358", "@@", "202.14")
    assert_equal(validar_venta(v5), String("cantidadProductos no recuperable o fuera de rango 1-10"))
    var v6 = lista("1", "731794571", "2358", "99", "202.14")
    assert_equal(validar_venta(v6), String("cantidadProductos no recuperable o fuera de rango 1-10"))
    var v7 = List[String]()
    assert_equal(validar_venta(v7), String("estructura: se esperaban 5 campos"))   # vacío

    print("test_validacion: todos los escenarios OK")
