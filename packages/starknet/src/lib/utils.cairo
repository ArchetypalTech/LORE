
#[generate_trait]
pub impl ByteArrayImpl of ByteArrayTrait {

    fn byte_array_from_bool(value: bool) -> ByteArray {
        (if value {"True"} else {"False"})
    }

    fn byte_array_from_felt252(mut value: felt252) -> ByteArray {
        let mut remaining: u256 = value.try_into().unwrap();
        let mut result: ByteArray = "";

        while remaining > 0 {
            let (quotient, remainder) = DivRem::div_rem(remaining, 256);
            let byte: u8 = remainder.try_into().unwrap();
            result.append_byte(byte);
            remaining = quotient;
        };

        return result.rev();
    }
}
