use core::traits::{TryInto};
use core::result::{Result};

#[generate_trait]
pub impl ByteArrayTraitExt of ByteArrayTrait {
    #[inline]
    fn felt252_at(self: ByteArray, index: usize) -> felt252 {
        let b: u8 = self.at(index).unwrap();
        let byte: felt252 = b.try_into().unwrap();
        byte
    }

    #[inline]
    fn equals(self: ByteArray, other: ByteArray) -> bool {
        let mut equals: bool = true;
        for i in 0..self.len() {
            if self.at(i).unwrap() != other.at(i).unwrap() {
                equals = false;
                break;
            }
        };
        equals
    }

    #[inline]
    fn to_felt252_word(self: ByteArray) -> Result<felt252, felt252> {
        if (self.len() >= 31) {
            return Result::Err(0);
        }
        let mut result: felt252 = 0;
        for c in 0..self.len() {
            let b: u8 = self.at(c).unwrap();
            result = result * 256;
            result = result + b.into();
        };
        Result::Ok(result)
    }

    fn split_into_words(self: ByteArray) -> Array<ByteArray> {
        let mut words: Array<ByteArray> = ArrayTrait::new();
        let mut current_word: ByteArray = "";
        for i in 0..self.len() {
            if (i >= self.len()) {
                break;
            }
            let byte: felt252 = self.clone().felt252_at(i);
            let characters: Array<felt252> = array![' ', '.', ',', '!', '?'];
            let mut is_terminator: bool = false;
            for c in characters {
                if byte == c {
                    is_terminator = true;
                    if current_word.len() > 0 {
                        words.append(current_word);
                        current_word = "";
                        is_terminator = true;
                        break;
                    }
                }
            };
            if !is_terminator {
                let b: u8 = byte.try_into().unwrap();
                current_word.append_byte(b);
            };
        };
        if (current_word.len() > 0) {
            words.append(current_word);
        }
        words
    }

    fn ends_with(self: @ByteArray, suffix: @ByteArray) -> bool {
        let self_len = self.len();
        let suffix_len = suffix.len();

        // If suffix is longer than self, it can’t be a suffix by definition,
        // so we skip all further logic and immediately return false.
        if suffix_len > self_len {
            return false;
        }

        // Create a mutable variable that we assume is true.
        // Change it to false only if we find a mismatch during the loop.
        let mut ends_with = true;

        // Compare each byte in suffix to the corresponding byte at the end of self
        for i in 0..suffix_len {
            if self.at(self_len - suffix_len + i).unwrap() != suffix.at(i).unwrap() {
                ends_with = false;
                break;
            }
        };

        // Return the result stored in ends_with
        ends_with
    }

    fn starts_with(self: @ByteArray, prefix: @ByteArray) -> bool {
        let self_len = self.len();
        let prefix_len = prefix.len();

        // If prefix is longer than self, it can’t be a prefix by definition,
        // so we skip all further logic and immediately return false.
        if prefix_len > self_len {
            return false;
        }

        // Create a mutable variable that we assume is true.
        // Change it to false only if we find a mismatch during the loop.
        let mut starts_with = true;

        // Compare each byte in prefix to the corresponding byte at the start of self
        for i in 0..prefix_len {
            if self.at(i).unwrap() != prefix.at(i).unwrap() {
                starts_with = false;
                break;
            }
        };

        // Return the result stored in starts_with
        starts_with
    }

    fn contains(self: @ByteArray, substring: @ByteArray) -> bool {
        let self_len = self.len();
        let substring_len = substring.len();

        // If substring is longer than self, it can’t be a substring
        if substring_len > self_len {
            return false;
        }

        // Set default to false — assume that is not found until proven
        let mut found = false;

        // Compute the max starting index for checking substring
        let max_start = self_len - substring_len + 1;

        // Slide a window over self
        for i in 0..max_start {
            let mut matched = true;

            for j in 0..substring_len {
                let self_byte = self.at(i + j).unwrap();
                let sub_byte = substring.at(j).unwrap();

                if self_byte != sub_byte {
                    matched = false;
                    break;
                }
            };

            if matched {
                found = true;
                break;
            }
        };

        found
    }

    fn to_lowercase(self: ByteArray) -> ByteArray {
        let mut result: ByteArray = "";
        for i in 0..self.len() {
            let byte: felt252 = self.clone().felt252_at(i);
            let mut b: u8 = byte.try_into().unwrap();

            // ASCII 'A' = 65, 'Z' = 90
            // ASCII 'a' = 97, 'z' = 122
            if b >= 65_u8 && b <= 90_u8 {
                b = b + 32_u8; // convert to lowercase
            }
            result.append_byte(b);
        };
        result
    }
}

#[generate_trait]
pub impl ClousureTraitImp of ClousureTrait {
    #[inline(never)]
    fn filter<
        T,
        +Copy<T>,
        +Drop<T>,
        F,
        +Drop<F>,
        impl func: core::ops::Fn<F, (T,)>[Output: bool],
        +Drop<func::Output>,
    >(
        self: Array<T>, f: F,
    ) -> Array<T> {
        let mut output: Array<T> = array![];
        for elem in self {
            if f(elem) {
                output.append(elem);
            }
        };
        output
    }

    #[inline(never)]
    fn map<T, +Drop<T>, F, +Drop<F>, impl func: core::ops::Fn<F, (T,)>, +Drop<func::Output>>(
        self: Array<T>, f: F,
    ) -> Array<func::Output> {
        let mut output: Array<func::Output> = array![];
        for elem in self {
            output.append(f(elem));
        };
        output
    }
}

#[cfg(test)]
mod tests {
    use super::ByteArrayTraitExt;
    use super::ClousureTrait;

    #[test]
    fn ByteArrayExt_to_felt252_word() {
        let a: ByteArray = "extravaganza";
        let a_converted = a.clone().to_felt252_word().unwrap();
        // let a_original: felt252 = 'extravaganza';
        // println!("{}, a_converted: {}, a_original: {}", a, a_converted.clone(), a_original);
        let b: ByteArray = "hello";
        let b_converted = b.clone().to_felt252_word().unwrap();
        // let b_original: felt252 = 'hello';
        // println!("{}, b_converted: {}, b_original: {}", b, b_converted.clone(), b_original);
        let c: ByteArray = "cairo";
        let c_converted = c.clone().to_felt252_word().unwrap();
        // let c_original: felt252 = 'cairo';
        // println!("{}, c_converted: {}, b_original: {}", c, c_converted.clone(), c_original);
        assert(a_converted == 'extravaganza'.into(), 'a_converted == "extravaganza"');
        assert(b_converted == 'hello'.into(), 'b_converted == "hello"');
        assert(c_converted == 'cairo'.into(), 'c_converted == "cairo"');
    }

    #[test]
    fn ByteArrayExt_to_byte() {
        let a: ByteArray = "hello";
        assert(a.clone().felt252_at(0) == 'h', 'a.at(0) == "h"');
        assert(a.clone().felt252_at(1) == 'e', 'a.at(1) == "e"');
        assert(a.clone().felt252_at(2) == 'l', 'a.at(2) == "l"');
        assert(a.clone().felt252_at(3) == 'l', 'a.at(3) == "l"');
        assert(a.clone().felt252_at(a.len() - 1) == 'o', 'a.at(4) == "o"');
    }

    #[test]
    fn ByteArrayExt_equality() {
        let a: ByteArray = "hello";
        let b: ByteArray = "hello";
        let c: ByteArray = "world";
        assert(a.clone().equals(b), 'a and b are equal');
        assert(!a.equals(c), 'a and c are not equal');
    }

    #[test]
    fn ByteArrayExt_test_split_into_words() {
        let input: ByteArray = "hello world! Can you believe it? It's all so good";
        let words = input.split_into_words().clone();
        let word1: ByteArray = "hello";
        let word2: ByteArray = "good";
        let w1: ByteArray = words.at(0).clone();
        let w2: ByteArray = words.at(words.len() - 1).clone();
        // println!("words: {:?}, length: {}", words, words.len());
        assert(words.len() == 10, 'words.len() == 10');
        assert(!word1.clone().equals(word2.clone()), 'word1 and word2 not similar');
        assert(!w1.clone().equals(w2.clone()), 'w1 and w2 not similar');
        assert(w1.equals(word1), 'words[0] == "hello".into()');
        assert(w2.equals(word2), 'words[1] == b"world".into()');
    }

    #[test]
    fn ByteArrayExt_ends_with() {
        let input: ByteArray = "meeting";
        let suffix: ByteArray = "ing";
        let expected_result: bool = true;
        let end_with: bool = input.ends_with(@suffix);
        assert_eq!(end_with, expected_result, "ending should be true");

        let input: ByteArray = "cook";
        let suffix: ByteArray = "ing";
        let expected_result: bool = false;
        let end_with: bool = input.ends_with(@suffix);
        assert_eq!(end_with, expected_result, "ending should be false");
    }

    fn ByteArrayExt_starts_with() {
        let input: ByteArray = "reusable";
        let prefix: ByteArray = "re";
        let expected_result: bool = true;
        let end_with: bool = input.starts_with(@prefix);
        assert_eq!(end_with, expected_result, "starting should be true");

        let input: ByteArray = "cowork";
        let prefix: ByteArray = "re";
        let expected_result: bool = false;
        let end_with: bool = input.starts_with(@prefix);
        assert_eq!(end_with, expected_result, "starting should be false");
    }

    #[test]
    fn ByteArrayExt_contains() {
        let input: ByteArray = "reusable";
        let substring: ByteArray = "usab";
        let expected_result: bool = true;
        let end_with: bool = input.contains(@substring);
        assert_eq!(end_with, expected_result, "containing should be true");

        let input: ByteArray = "cowork";
        let substring: ByteArray = "re";
        let expected_result: bool = false;
        let end_with: bool = input.contains(@substring);
        assert_eq!(end_with, expected_result, "containing should be false");
    }

    #[test]
    fn ByteArrayExt_to_lowercase() {
        let input: ByteArray = "REUSABLE";
        let expected_result: ByteArray = "reusable";
        let end_with: ByteArray = input.to_lowercase();
        assert_eq!(end_with, expected_result, "lowercase should be true");

        let input: ByteArray = "Cowork";
        let expected_result: ByteArray = "cowork";
        let end_with: ByteArray = input.to_lowercase();
        assert_eq!(end_with, expected_result, "lowercase should be false");

        let input: ByteArray = "BoOm";
        let expected_result: ByteArray = "boom";
        let end_with: ByteArray = input.to_lowercase();
        assert_eq!(end_with, expected_result, "lowercase should be false");
    }

    #[test]
    fn test_map() {
        // Create a test Array with some values
        let mut input_array: Array = ArrayTrait::new();
        input_array.append(1);
        input_array.append(2);
        input_array.append(3);
        input_array.append(4);
        input_array.append(5);

        // Define a closure that doubles each value
        let closure = |x: i32| x * 2;

        // Apply the map function
        let output_array = input_array.map(closure);

        // Expected output is a doubled array
        let mut expected_output: Array = ArrayTrait::new();
        expected_output.append(2);
        expected_output.append(4);
        expected_output.append(6);
        expected_output.append(8);
        expected_output.append(10);

        // Assert that the result matches the expected output
        assert_eq!(output_array, expected_output, "elements should be doubled");
    }
}
