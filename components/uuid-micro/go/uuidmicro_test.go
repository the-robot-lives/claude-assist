package uuidmicro

import (
	"strings"
	"testing"
)

const fixtureUUID = "5c692577-ad0c-51f1-992c-759b5e5fffb5"
const fixtureToken = "𓳔𔐮𔘟𔄵"

func TestEncodeGoldenFixture(t *testing.T) {
	token, err := Encode(fixtureUUID)
	if err != nil {
		t.Fatal(err)
	}
	if token != fixtureToken {
		t.Fatalf("expected %q, got %q", fixtureToken, token)
	}

	points, err := Codepoints(fixtureUUID)
	if err != nil {
		t.Fatal(err)
	}
	if strings.Join(points, " ") != "U+13CD4 U+1442E U+1461F U+14135" {
		t.Fatalf("unexpected codepoints: %v", points)
	}
}

func TestIsToken(t *testing.T) {
	if !IsToken(fixtureToken) {
		t.Fatal("fixture should validate")
	}
	if IsToken("ABCD") {
		t.Fatal("ASCII should not validate as a generated uuid-micro token")
	}
}
