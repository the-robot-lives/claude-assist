"use strict";

const TOKEN_RANGES = [
  [0x10980, 0x1099f],
  [0x13000, 0x1342f],
  [0x13460, 0x143ff],
  [0x14400, 0x1467f],
];

const TOKEN_LENGTH = 4;
const TOKEN_SIZE = TOKEN_RANGES.reduce((total, [start, end]) => total + BigInt(end - start + 1), 0n);

function encode(uuid) {
  const hex = String(uuid).trim().replaceAll("-", "");
  if (!/^[0-9a-fA-F]{32}$/.test(hex)) {
    throw new Error("invalid UUID");
  }
  let number = BigInt(`0x${hex}`) % (TOKEN_SIZE ** BigInt(TOKEN_LENGTH));
  const chars = [];
  for (let i = 0; i < TOKEN_LENGTH; i += 1) {
    const index = number % TOKEN_SIZE;
    number /= TOKEN_SIZE;
    chars.push(tokenChar(Number(index)));
  }
  return chars.reverse().join("");
}

function codepoints(uuid) {
  return [...encode(uuid)].map((ch) => `U+${ch.codePointAt(0).toString(16).toUpperCase()}`);
}

function isToken(value) {
  const chars = [...String(value)];
  return chars.length === TOKEN_LENGTH && chars.every(isTokenChar);
}

function tokenChar(index) {
  let n = index;
  for (const [start, end] of TOKEN_RANGES) {
    const size = end - start + 1;
    if (n < size) {
      return String.fromCodePoint(start + n);
    }
    n -= size;
  }
  throw new Error("token alphabet index out of range");
}

function isTokenChar(ch) {
  const point = ch.codePointAt(0);
  return TOKEN_RANGES.some(([start, end]) => point >= start && point <= end);
}

module.exports = {
  TOKEN_LENGTH,
  TOKEN_RANGES,
  TOKEN_SIZE: Number(TOKEN_SIZE),
  codepoints,
  encode,
  isToken,
};
