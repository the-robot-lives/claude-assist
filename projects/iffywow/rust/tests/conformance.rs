//! Drives every golden vector in `../conformance/*.jsonl`, both directions
//! where defined (SDK-INTERFACE.md §5).

use std::fs;

use num_bigint::BigUint;
use serde_json::Value;

use ithkuil::codec::{deserialize_term, rank, serialize_term, unrank, Term};
use ithkuil::{
    from_bytes, from_integer, from_integer_string, from_latin, from_wire, from_wire_json,
    to_bytes, to_integer, to_integer_string, to_latin, to_wire, to_wire_json,
};

fn vectors(name: &str) -> Vec<Value> {
    let path = format!("{}/../conformance/{name}", env!("CARGO_MANIFEST_DIR"));
    let content =
        fs::read_to_string(&path).unwrap_or_else(|e| panic!("cannot read {path}: {e}"));
    content
        .lines()
        .map(str::trim)
        .filter(|line| !line.is_empty())
        .map(|line| {
            serde_json::from_str(line)
                .unwrap_or_else(|e| panic!("bad JSONL line in {name}: {e}\n{line}"))
        })
        .collect()
}

fn hex_decode(s: &str) -> Vec<u8> {
    assert!(s.len() % 2 == 0, "odd-length hex string {s:?}");
    (0..s.len())
        .step_by(2)
        .map(|i| {
            u8::from_str_radix(&s[i..i + 2], 16)
                .unwrap_or_else(|e| panic!("bad hex {s:?}: {e}"))
        })
        .collect()
}

fn hex_encode(bytes: &[u8]) -> String {
    bytes.iter().map(|b| format!("{b:02x}")).collect()
}

fn big(s: &str) -> BigUint {
    BigUint::parse_bytes(s.as_bytes(), 10).unwrap_or_else(|| panic!("bad decimal {s:?}"))
}

/// Build a codec term from the conformance JSON shape:
/// `["nat", n]`, `["pair", x, y]`, `["list", [...]]`, `["bytes", "<hex>"]`.
fn term_from_json(value: &Value) -> Term {
    let arr = value.as_array().expect("term must be an array");
    match arr[0].as_str().expect("term kind must be a string") {
        "nat" => Term::Nat(BigUint::from(arr[1].as_u64().expect("nat value"))),
        "pair" => Term::Pair(
            Box::new(term_from_json(&arr[1])),
            Box::new(term_from_json(&arr[2])),
        ),
        "list" => Term::List(
            arr[1]
                .as_array()
                .expect("list items")
                .iter()
                .map(term_from_json)
                .collect(),
        ),
        "bytes" => Term::Bytes(hex_decode(arr[1].as_str().expect("bytes hex"))),
        kind => panic!("unknown term kind {kind:?}"),
    }
}

#[test]
fn codec_units() {
    let rows = vectors("codec_units.jsonl");
    assert!(!rows.is_empty());
    for row in rows {
        assert_eq!(row["kind"], "term", "unexpected row kind: {row}");
        let term = term_from_json(&row["term"]);
        let bytes_hex = row["bytes"].as_str().unwrap();
        let bytes = hex_decode(bytes_hex);
        let integer = big(row["integer"].as_str().unwrap());

        // ser / de.
        assert_eq!(hex_encode(&serialize_term(&term)), bytes_hex, "ser: {row}");
        assert_eq!(deserialize_term(&bytes).unwrap(), term, "de: {row}");
        // rank / unrank.
        assert_eq!(rank(&bytes), integer, "rank: {row}");
        assert_eq!(unrank(&integer), bytes, "unrank: {row}");
    }
}

#[test]
fn coordinate_to_integer() {
    let rows = vectors("coordinate_to_integer.jsonl");
    assert!(!rows.is_empty());
    for row in rows {
        let word = from_wire(&row["coordinate"])
            .unwrap_or_else(|e| panic!("from_wire failed on {row}: {e}"));
        let bytes_hex = row["bytes"].as_str().unwrap();
        let bytes = hex_decode(bytes_hex);
        let integer_str = row["integer"].as_str().unwrap();
        let integer = big(integer_str);

        // bytes, both directions.
        assert_eq!(hex_encode(&to_bytes(&word).unwrap()), bytes_hex, "{row}");
        assert_eq!(from_bytes(&bytes).unwrap(), word, "{row}");
        // integer, both directions.
        assert_eq!(to_integer(&word).unwrap(), integer, "{row}");
        assert_eq!(from_integer(&integer).unwrap(), word, "{row}");
        // integer string, both directions.
        assert_eq!(to_integer_string(&word).unwrap(), integer_str, "{row}");
        assert_eq!(from_integer_string(integer_str).unwrap(), word, "{row}");
        // canonical wire, both directions.
        assert_eq!(to_wire(&word), row["coordinate"], "{row}");
        assert_eq!(from_wire_json(&to_wire_json(&word)).unwrap(), word, "{row}");
    }
}

#[test]
fn invalid_inputs() {
    let rows = vectors("invalid_inputs.jsonl");
    assert!(!rows.is_empty());
    for row in rows {
        let expected = row["error"].as_str().unwrap();
        let kind = row["kind"].as_str().unwrap();
        let error = match kind {
            "integer_string" => from_integer_string(row["value"].as_str().unwrap())
                .expect_err(&format!("expected rejection: {row}")),
            "bytes" => from_bytes(&hex_decode(row["value"].as_str().unwrap()))
                .expect_err(&format!("expected rejection: {row}")),
            "coordinate" => {
                from_wire(&row["value"]).expect_err(&format!("expected rejection: {row}"))
            }
            other => panic!("unknown invalid-input kind {other:?}"),
        };
        assert_eq!(error.code(), expected, "vector: {row}, got error: {error}");
    }
}

#[test]
fn latin_to_coordinate() {
    let rows = vectors("latin_to_coordinate.jsonl");
    assert!(!rows.is_empty());
    for row in rows {
        let latin = row["latin"].as_str().unwrap();

        if let Some(expected) = row.get("error") {
            let expected = expected.as_str().unwrap();
            match from_latin(latin) {
                Err(e) => assert_eq!(e.code(), expected, "vector: {row}, got: {e}"),
                Ok(word) => panic!("expected {expected} for {latin:?}, got {word:?}"),
            }
            continue;
        }

        let canonical = row["canonical"].as_str().unwrap();
        let word =
            from_latin(latin).unwrap_or_else(|e| panic!("from_latin({latin:?}) failed: {e}"));

        // from_latin(latin) == coordinate (compared in wire form).
        assert_eq!(to_wire(&word), row["coordinate"], "wire mismatch: {row}");
        // to_latin(coordinate) == canonical.
        assert_eq!(to_latin(&word).unwrap(), canonical, "{row}");
        // The wire vector itself parses to the same word and spelling.
        let from_vector = from_wire(&row["coordinate"]).unwrap();
        assert_eq!(from_vector, word, "{row}");
        assert_eq!(to_latin(&from_vector).unwrap(), canonical, "{row}");
        // Canonical spelling round-trips (from_latin ∘ to_latin law).
        assert_eq!(from_latin(canonical).unwrap(), word, "{row}");
    }
}
