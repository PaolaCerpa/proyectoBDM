from std.testing import assert_equal, assert_true, assert_false
from limpieza import es_solo_digitos, limpiar_valor_numerico


def main() raises:
    # es_solo_digitos: válido, inválido, vacío
    assert_true(es_solo_digitos("190252420"))
    assert_false(es_solo_digitos("@10@93@!65"))
    assert_false(es_solo_digitos(""))

    # limpiar_valor_numerico: válido, inválido recuperable, no recuperable
    assert_equal(limpiar_valor_numerico("123"), String("123"))
    assert_equal(limpiar_valor_numerico("2x"), String("2"))
    assert_equal(limpiar_valor_numerico("10K"), String("10"))
    assert_equal(limpiar_valor_numerico(""), String(""))
    assert_equal(limpiar_valor_numerico("@!$"), String(""))

    print("test_limpieza: 8 comprobaciones OK")
