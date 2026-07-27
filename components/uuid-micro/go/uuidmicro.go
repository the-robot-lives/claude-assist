package uuidmicro

import (
	"encoding/hex"
	"errors"
	"fmt"
	"math/big"
	"strings"
	"unicode/utf8"
)

type TokenRange struct {
	Start rune
	End   rune
}

var TokenRanges = []TokenRange{
	{0x10980, 0x1099F},
	{0x13000, 0x1342F},
	{0x13460, 0x143FF},
	{0x14400, 0x1467F},
}

const TokenLength = 4
const TokenSize = 5744

func Encode(uuid string) (string, error) {
	bytes, err := parseUUID(uuid)
	if err != nil {
		return "", err
	}

	base := big.NewInt(TokenSize)
	modulus := new(big.Int).Exp(base, big.NewInt(TokenLength), nil)
	number := new(big.Int).SetBytes(bytes)
	number.Mod(number, modulus)

	chars := make([]rune, TokenLength)
	rem := new(big.Int)
	for i := TokenLength - 1; i >= 0; i-- {
		number.QuoRem(number, base, rem)
		chars[i] = tokenRune(int(rem.Int64()))
	}
	return string(chars), nil
}

func Codepoints(uuid string) ([]string, error) {
	token, err := Encode(uuid)
	if err != nil {
		return nil, err
	}
	points := make([]string, 0, TokenLength)
	for _, ch := range token {
		points = append(points, fmt.Sprintf("U+%X", ch))
	}
	return points, nil
}

func IsToken(token string) bool {
	if utf8.RuneCountInString(token) != TokenLength {
		return false
	}
	for _, ch := range token {
		if !isTokenRune(ch) {
			return false
		}
	}
	return true
}

func parseUUID(value string) ([]byte, error) {
	hexValue := strings.ReplaceAll(strings.TrimSpace(value), "-", "")
	if len(hexValue) != 32 {
		return nil, errors.New("invalid UUID length")
	}
	bytes, err := hex.DecodeString(hexValue)
	if err != nil {
		return nil, err
	}
	return bytes, nil
}

func tokenRune(index int) rune {
	for _, r := range TokenRanges {
		size := int(r.End - r.Start + 1)
		if index < size {
			return r.Start + rune(index)
		}
		index -= size
	}
	panic("token alphabet index out of range")
}

func isTokenRune(ch rune) bool {
	for _, r := range TokenRanges {
		if ch >= r.Start && ch <= r.End {
			return true
		}
	}
	return false
}
