from std.testing import assert_equal
from std.collections import Set
from validacion import validar_integridad_referencial


def main() raises:
    var personas = Set[String]()
    personas.add("731794571")
    personas.add("190252420")
    var articulos = Set[String]()
    articulos.add("358")
    articulos.add("847")

    # válido: comprador y artículo existen
    assert_equal(validar_integridad_referencial("731794571", "847", personas, articulos), String(""))

    # inválido: comprador inexistente / artículo inexistente
    assert_equal(
        validar_integridad_referencial("999999999", "847", personas, articulos),
        String("idComprador sin persona asociada"),
    )
    assert_equal(
        validar_integridad_referencial("731794571", "2358", personas, articulos),
        String("idArticulo sin artículo asociado"),
    )

    # vacío: id vacío y conjuntos vacíos
    assert_equal(
        validar_integridad_referencial("", "847", personas, articulos),
        String("idComprador sin persona asociada"),
    )
    var sin_personas = Set[String]()
    var sin_articulos = Set[String]()
    assert_equal(
        validar_integridad_referencial("731794571", "847", sin_personas, sin_articulos),
        String("idComprador sin persona asociada"),
    )

    print("test_integridad: todos los escenarios OK")
