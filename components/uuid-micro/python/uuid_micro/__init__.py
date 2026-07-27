from __future__ import annotations

from uuid import UUID

TOKEN_RANGES: tuple[tuple[int, int], ...] = (
    (0x10980, 0x1099F),
    (0x13000, 0x1342F),
    (0x13460, 0x143FF),
    (0x14400, 0x1467F),
)
TOKEN_LENGTH = 4
TOKEN_SIZE = sum(end - start + 1 for start, end in TOKEN_RANGES)


def encode(value: str | UUID) -> str:
    uuid = value if isinstance(value, UUID) else UUID(str(value))
    number = int.from_bytes(uuid.bytes, "big") % (TOKEN_SIZE**TOKEN_LENGTH)
    chars: list[str] = []
    for _ in range(TOKEN_LENGTH):
        number, index = divmod(number, TOKEN_SIZE)
        chars.append(_token_char(index))
    return "".join(reversed(chars))


def codepoints(value: str | UUID) -> list[str]:
    return [f"U+{ord(ch):X}" for ch in encode(value)]


def is_token(value: str) -> bool:
    return len(value) == TOKEN_LENGTH and all(_is_token_char(ch) for ch in value)


def _token_char(index: int) -> str:
    for start, end in TOKEN_RANGES:
        size = end - start + 1
        if index < size:
            return chr(start + index)
        index -= size
    raise ValueError("token alphabet index out of range")


def _is_token_char(ch: str) -> bool:
    point = ord(ch)
    return any(start <= point <= end for start, end in TOKEN_RANGES)


__all__ = ["TOKEN_LENGTH", "TOKEN_RANGES", "TOKEN_SIZE", "codepoints", "encode", "is_token"]
