use uuid::Uuid;

pub const TOKEN_RANGES: [(u32, u32); 4] = [
    (0x10980, 0x1099F),
    (0x13000, 0x1342F),
    (0x13460, 0x143FF),
    (0x14400, 0x1467F),
];
pub const TOKEN_LENGTH: usize = 4;
pub const TOKEN_SIZE: u128 = token_alphabet_size();

const fn token_alphabet_size() -> u128 {
    let mut total = 0u128;
    let mut index = 0usize;
    while index < TOKEN_RANGES.len() {
        let (start, end) = TOKEN_RANGES[index];
        total += (end - start + 1) as u128;
        index += 1;
    }
    total
}

pub fn encode(value: Uuid) -> String {
    let mut number = u128::from_be_bytes(*value.as_bytes()) % TOKEN_SIZE.pow(TOKEN_LENGTH as u32);
    let mut chars = Vec::with_capacity(TOKEN_LENGTH);
    for _ in 0..TOKEN_LENGTH {
        let index = (number % TOKEN_SIZE) as u32;
        number /= TOKEN_SIZE;
        chars.push(token_char_from_index(index));
    }
    chars.into_iter().rev().collect()
}

pub fn encode_str(value: &str) -> Result<String, uuid::Error> {
    Uuid::parse_str(value).map(encode)
}

pub fn codepoints(value: Uuid) -> Vec<String> {
    encode(value)
        .chars()
        .map(|ch| format!("U+{:X}", ch as u32))
        .collect()
}

pub fn is_token(value: &str) -> bool {
    value.chars().count() == TOKEN_LENGTH && value.chars().all(is_token_char)
}

fn token_char_from_index(mut index: u32) -> char {
    for &(start, end) in TOKEN_RANGES.iter() {
        let range_size = end - start + 1;
        if index < range_size {
            return char::from_u32(start + index).expect("valid token code point");
        }
        index -= range_size;
    }
    panic!("token alphabet index out of range");
}

fn is_token_char(ch: char) -> bool {
    let n = ch as u32;
    TOKEN_RANGES
        .iter()
        .any(|(start, end)| (*start..=*end).contains(&n))
}

#[cfg(test)]
mod tests {
    use super::*;

    const FIXTURE: &str = "5c692577-ad0c-51f1-992c-759b5e5fffb5";
    const TOKEN: &str = "𓳔𔐮𔘟𔄵";

    #[test]
    fn encodes_golden_fixture() {
        let uuid = Uuid::parse_str(FIXTURE).unwrap();
        assert_eq!(TOKEN_SIZE, 5744);
        assert_eq!(encode(uuid), TOKEN);
        assert_eq!(
            codepoints(uuid).join(" "),
            "U+13CD4 U+1442E U+1461F U+14135"
        );
        assert_eq!(encode_str(FIXTURE).unwrap(), TOKEN);
    }

    #[test]
    fn validates_tokens() {
        assert!(is_token(TOKEN));
        assert!(!is_token("ABCD"));
        assert!(!is_token("𓳔𔐮𔘟"));
    }
}
