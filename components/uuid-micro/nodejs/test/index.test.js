"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");
const uuidMicro = require("../src");

const FIXTURE_UUID = "5c692577-ad0c-51f1-992c-759b5e5fffb5";
const FIXTURE_TOKEN = "𓳔𔐮𔘟𔄵";

test("encodes golden fixture", () => {
  assert.equal(uuidMicro.TOKEN_SIZE, 5744);
  assert.equal(uuidMicro.encode(FIXTURE_UUID), FIXTURE_TOKEN);
  assert.deepEqual(uuidMicro.codepoints(FIXTURE_UUID), [
    "U+13CD4",
    "U+1442E",
    "U+1461F",
    "U+14135",
  ]);
});

test("validates tokens", () => {
  assert.equal(uuidMicro.isToken(FIXTURE_TOKEN), true);
  assert.equal(uuidMicro.isToken("ABCD"), false);
  assert.equal(uuidMicro.isToken("𓳔𔐮𔘟"), false);
});
