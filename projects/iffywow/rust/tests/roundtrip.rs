//! Property tests for the §5 laws of SDK-INTERFACE.md over a deterministic,
//! seeded generator (simple LCG + output mixing — no rand crate).

use num_bigint::BigUint;

use ithkuil::{
    canonicalize, from_bytes, from_integer, from_integer_string, from_latin, from_wire,
    from_wire_json, to_bytes, to_integer, to_integer_string, to_latin, to_wire, to_wire_json,
    validate, Glyph, Modifier, Socket, Word,
};

/// Deterministic generator: 64-bit LCG state with an xorshift-multiply
/// output mix (splitmix-style), so low bits are usable.
struct Lcg(u64);

impl Lcg {
    fn new(seed: u64) -> Self {
        Lcg(seed)
    }

    fn next_u64(&mut self) -> u64 {
        self.0 = self
            .0
            .wrapping_mul(6364136223846793005)
            .wrapping_add(1442695040888963407);
        let mut x = self.0;
        x ^= x >> 33;
        x = x.wrapping_mul(0xff51afd7ed558ccd);
        x ^= x >> 33;
        x
    }

    /// Uniform-ish value in `0..n` (n > 0). Modulo bias is irrelevant here.
    fn below(&mut self, n: u64) -> u64 {
        self.next_u64() % n
    }

    fn chance(&mut self, percent: u64) -> bool {
        self.below(100) < percent
    }
}

/// Open enum id: mostly small, sometimes at or near the u64 boundary.
fn gen_open_id(rng: &mut Lcg) -> u64 {
    match rng.below(12) {
        0 => u64::MAX,
        1 => rng.next_u64(),
        2 => 1u64 << 40,
        3 => 0,
        _ => rng.below(500),
    }
}

fn gen_modifier(rng: &mut Lcg, depth: u32) -> Modifier {
    let diacritic_count = rng.below(3);
    Modifier {
        shape: gen_open_id(rng),
        orientation: rng.below(4) as u8,
        diacritics: (0..diacritic_count).map(|_| gen_open_id(rng)).collect(),
        sockets: if depth == 0 {
            Vec::new()
        } else {
            gen_sockets(rng, depth - 1, 25)
        },
    }
}

/// Sockets generated in ascending id order (canonical) with the given
/// per-socket occupancy percentage.
fn gen_sockets(rng: &mut Lcg, depth: u32, percent: u64) -> Vec<Socket> {
    let mut sockets = Vec::new();
    for id in 0u8..=7 {
        if rng.chance(percent) {
            sockets.push(Socket {
                id,
                modifier: gen_modifier(rng, depth),
            });
        }
    }
    sockets
}

fn gen_word(rng: &mut Lcg) -> Word {
    let version = if rng.chance(80) {
        1
    } else {
        1 + rng.below(1000) as u32
    };
    let glyph_count = rng.below(4); // 0..=3
    Word {
        version,
        glyphs: (0..glyph_count)
            .map(|_| Glyph {
                character_class: gen_open_id(rng),
                base: gen_open_id(rng),
                orientation: rng.below(4) as u8,
                // depth 2 below the glyph level => total socket nesting <= 3.
                sockets: gen_sockets(rng, 2, 35),
            })
            .collect(),
    }
}

#[test]
fn roundtrip_laws() {
    let mut rng = Lcg::new(0x5eed_1502_beef_cafe);
    for i in 0..300 {
        let word = gen_word(&mut rng);

        validate(&word).unwrap_or_else(|e| panic!("word {i} failed validate: {e}\n{word:?}"));
        assert_eq!(canonicalize(&word).unwrap(), word, "word {i}: already canonical");

        // from_bytes(to_bytes(c)) == c
        let bytes = to_bytes(&word).unwrap();
        assert_eq!(from_bytes(&bytes).unwrap(), word, "bytes law, word {i}");

        // from_integer(to_integer(c)) == c
        let integer = to_integer(&word).unwrap();
        assert_eq!(from_integer(&integer).unwrap(), word, "integer law, word {i}");

        // from_integer_string(to_integer_string(c)) == c
        let integer_string = to_integer_string(&word).unwrap();
        assert_eq!(
            from_integer_string(&integer_string).unwrap(),
            word,
            "integer-string law, word {i}"
        );

        // from_wire(to_wire(c)) == c
        let wire = to_wire(&word);
        assert_eq!(from_wire(&wire).unwrap(), word, "wire law, word {i}");

        // from_wire_json(to_wire_json(c)) == c
        let json = to_wire_json(&word);
        assert_eq!(from_wire_json(&json).unwrap(), word, "wire-json law, word {i}");
    }
}

#[test]
fn romanization_roundtrip_laws() {
    // In-profile coordinates: to_latin then from_latin must be identity, and
    // from_latin(to_latin(c)) == c == canonicalize(c).
    let mut rng = Lcg::new(0x0c0d_ec01);
    for i in 0..100 {
        let stem = rng.below(4) as u8;
        let version_bit = rng.below(2) as u8;
        let function = rng.below(2) as u8;
        let spec = rng.below(4);
        let perspective = rng.below(4);
        let case_index = rng.below(9);
        let base = 1 + rng.below(551_880);
        let word = Word {
            version: 1,
            glyphs: vec![Glyph {
                character_class: 0,
                base,
                orientation: stem,
                sockets: vec![
                    Socket {
                        id: 0,
                        modifier: Modifier {
                            shape: spec,
                            orientation: function + 2 * version_bit,
                            diacritics: vec![],
                            sockets: vec![],
                        },
                    },
                    Socket {
                        id: 1,
                        modifier: Modifier {
                            shape: perspective,
                            orientation: 0,
                            diacritics: vec![],
                            sockets: vec![],
                        },
                    },
                    Socket {
                        id: 2,
                        modifier: Modifier {
                            shape: case_index,
                            orientation: 0,
                            diacritics: vec![],
                            sockets: vec![],
                        },
                    },
                ],
            }],
        };
        let latin = to_latin(&word).unwrap_or_else(|e| panic!("to_latin {i} failed: {e}"));
        assert_eq!(from_latin(&latin).unwrap(), word, "latin law, word {i}: {latin}");
        // Canonical spelling is a fixed point of preprocessing.
        assert_eq!(to_latin(&from_latin(&latin).unwrap()).unwrap(), latin);
    }
}

#[test]
fn from_integer_is_total_and_inverse_where_ok() {
    // Every natural decodes to *some* byte string; only canonical
    // serializations of valid words succeed — but nothing may panic, and
    // successes must invert.
    let mut rng = Lcg::new(42);
    for _ in 0..200 {
        let n = BigUint::from(rng.next_u64());
        if let Ok(word) = from_integer(&n) {
            assert_eq!(to_integer(&word).unwrap(), n);
        }
    }
    // The known smallest word: PAIR(NAT 1, LIST []) at E = 8606843649.
    let empty = from_integer_string("8606843649").unwrap();
    assert_eq!(
        empty,
        Word {
            version: 1,
            glyphs: vec![]
        }
    );
}

#[test]
fn wire_leniency_sorts_and_drops_empties() {
    let json = r#"["ithkuil-word", 1, [["glyph", 0, 5, 0,
        [[3, null], [2, ["modifier", 1, 0, [], []]], [0, ["modifier", 0, 0, [], []]]]]]]"#;
    let word = from_wire_json(json).unwrap();
    let sockets = &word.glyphs[0].sockets;
    assert_eq!(sockets.len(), 2, "empty socket [3, null] must be dropped");
    assert_eq!((sockets[0].id, sockets[1].id), (0, 2), "sockets sorted");
    assert_eq!(
        to_wire_json(&word),
        r#"["ithkuil-word",1,[["glyph",0,5,0,[[0,["modifier",0,0,[],[]]],[2,["modifier",1,0,[],[]]]]]]]"#
    );
}

#[test]
fn wire_duplicate_socket_always_errors() {
    // Duplicates error even when one side is null (never repaired).
    let json = r#"["ithkuil-word", 1, [["glyph", 0, 0, 0,
        [[1, null], [1, ["modifier", 0, 0, [], []]]]]]]"#;
    assert_eq!(from_wire_json(json).unwrap_err().code(), "duplicate_socket");
}

#[test]
fn native_canonicalize_sorts_but_never_repairs_duplicates() {
    let modifier = Modifier {
        shape: 0,
        orientation: 0,
        diacritics: vec![],
        sockets: vec![],
    };
    let unsorted = Word {
        version: 1,
        glyphs: vec![Glyph {
            character_class: 0,
            base: 1,
            orientation: 0,
            sockets: vec![
                Socket {
                    id: 4,
                    modifier: modifier.clone(),
                },
                Socket {
                    id: 1,
                    modifier: modifier.clone(),
                },
            ],
        }],
    };
    // Strict validation rejects; lenient canonicalization repairs order.
    assert_eq!(validate(&unsorted).unwrap_err().code(), "unsorted_sockets");
    let canonical = canonicalize(&unsorted).unwrap();
    let ids: Vec<u8> = canonical.glyphs[0].sockets.iter().map(|s| s.id).collect();
    assert_eq!(ids, vec![1, 4]);

    let duplicated = Word {
        version: 1,
        glyphs: vec![Glyph {
            character_class: 0,
            base: 1,
            orientation: 0,
            sockets: vec![
                Socket {
                    id: 2,
                    modifier: modifier.clone(),
                },
                Socket {
                    id: 2,
                    modifier,
                },
            ],
        }],
    };
    assert_eq!(
        canonicalize(&duplicated).unwrap_err().code(),
        "duplicate_socket"
    );
}
