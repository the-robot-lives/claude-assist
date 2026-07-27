import unittest

import uuid_micro


FIXTURE_UUID = "5c692577-ad0c-51f1-992c-759b5e5fffb5"
FIXTURE_TOKEN = "𓳔𔐮𔘟𔄵"


class UUIDMicroTest(unittest.TestCase):
    def test_encodes_golden_fixture(self):
        self.assertEqual(uuid_micro.TOKEN_SIZE, 5744)
        self.assertEqual(uuid_micro.encode(FIXTURE_UUID), FIXTURE_TOKEN)
        self.assertEqual(
            uuid_micro.codepoints(FIXTURE_UUID),
            ["U+13CD4", "U+1442E", "U+1461F", "U+14135"],
        )

    def test_validates_tokens(self):
        self.assertTrue(uuid_micro.is_token(FIXTURE_TOKEN))
        self.assertFalse(uuid_micro.is_token("ABCD"))
        self.assertFalse(uuid_micro.is_token("𓳔𔐮𔘟"))


if __name__ == "__main__":
    unittest.main()
