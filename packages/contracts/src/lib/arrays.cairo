
//
// Based on Alexandria array and span extensions
// https://github.com/keep-starknet-strange/alexandria/blob/main/packages/data_structures/src/array_ext.cairo
// https://github.com/keep-starknet-strange/alexandria/blob/main/packages/data_structures/src/span_ext.cairo
//

//
// Span utils
//
#[generate_trait]
pub impl SpanUtilsImpl<T, +Clone<T>, +Drop<T>> of SpanUtilsTrait<T> {
    //
    // from alexandria
    fn contains<+PartialEq<T>>(mut self: Span<T>, value: @T) -> bool {
        loop {
            match self.pop_front() {
                Option::Some(v) => { if v == value { break true; } },
                Option::None => { break false; },
            };
        }
    }
    fn position<+PartialEq<T>>(mut self: Span<T>, value: @T) -> Option<usize> {
        let mut index: usize = 0;
        loop {
            match self.pop_front() {
                Option::Some(v) => {
                    if v == value {
                        break Option::Some(index);
                    }
                    index += 1;
                },
                Option::None => { break Option::None; },
            };
        }
    }
    fn remove<+PartialEq<T>>(mut self: Span<T>, value: @T) -> Array<T> {
        let mut ret: Array<T> = array![];
        for v in self {
            if (v != value) {
                ret.append(v.clone());
            }
        };
        (ret)
    }
    fn concat(self: Span<T>, other: Span<T>) -> Array<T> {
        let mut ret: Array<T> = array![];
        ret.extend_from_span(self);
        ret.extend_from_span(other);
        (ret)
    }
}

//
// Array utils
//
#[generate_trait]
pub impl ArrayUtilsImpl<T, +Clone<T>, +Drop<T>> of ArrayUtilsTrait<T> {
    //
    // from alexandria
    fn contains<+PartialEq<T>>(self: @Array<T>, value: @T) -> bool {
        (self.span().contains(value))
    }
    fn position<+PartialEq<T>>(self: @Array<T>, value: @T) -> Option<usize> {
        (self.span().position(value))
    }
    fn remove<+PartialEq<T>>(self: @Array<T>, value: @T) -> Array<T> {
        (self.span().remove(value))
    }
    fn extend_from_span<+Destruct<T>>(ref self: Array<T>, mut other: Span<T>) {
        while let Option::Some(elem) = other.pop_front() {
            self.append(elem.clone());
        }
    }
    fn concat(self: @Array<T>, other: @Array<T>) -> Array<T> {
        (self.span().concat(other.span()))
    }
}

#[cfg(test)]
#[generate_trait]
pub impl ArrayTestUtilsImpl<T, +Clone<T>, +Drop<T>> of ArrayTestUtilsTrait<T> {
    fn assert_array_eq<+PartialEq<T>, +core::fmt::Debug<T>>(v1: Array<T>, v2: Array<T>, prefix: ByteArray) {
        assert_eq!(v1.len(), v2.len(), "[{}] Invalid values length", prefix);
        let mut i: usize = 0;
        while (i < v1.len()) {
            assert_eq!(v1.at(i), v2.at(i), "[{}] Invalid value {}", prefix, i);
            i += 1;
        }
    }
    fn assert_span_eq<+PartialEq<T>, +core::fmt::Debug<T>>(v1: Span<T>, v2: Span<T>, prefix: ByteArray) {
        assert_eq!(v1.len(), v2.len(), "[{}] Invalid values length", prefix);
        let mut i: usize = 0;
        while (i < v1.len()) {
            assert_eq!(v1.at(i), v2.at(i), "[{}] Invalid value {}", prefix, i);
            i += 1;
        }
    }
}


//----------------------------------------
// Defaults
//

pub impl SpanDefault<T, +Drop<T>> of Default<Span<T>> {
    fn default() -> Span<T> {
        let arr: Array<T> = ArrayTrait::<T>::new();
        (arr.span())
    }
}



//----------------------------------------
// Unit  tests
//
#[cfg(test)]
mod unit {
    use super::{ArrayUtilsTrait, SpanUtilsTrait};

    #[test]
    fn test_array_contains() {
        let arr0: Array<usize> = array![0, 2, 4];
        let arr1: Array<usize> = array![1, 3, 5];
        let span0: Span<usize> = arr0.span();
        let span1: Span<usize> = arr1.span();
        // test default values
        for i in 0..arr0.len() {
            if (i % 2 == 0) {
                assert!(arr0.contains(@i), "array_contains_0_!true");
                assert!(!arr1.contains(@i), "array_contains_1_!false");
                assert!(span0.contains(@i), "span_contains_0_!true");
                assert!(!span1.contains(@i), "span_contains_1_!false");
            }
        };
    }

    #[test]
    fn test_array_position() {
        let arr: Array<usize> = array![1, 3, 5];
        assert_eq!(arr.position(@0), Option::None);
        assert_eq!(arr.position(@1), Option::Some(0));
        assert_eq!(arr.position(@2), Option::None);
        assert_eq!(arr.position(@3), Option::Some(1));
        assert_eq!(arr.position(@4), Option::None);
        assert_eq!(arr.position(@5), Option::Some(2));
        assert_eq!(arr.position(@0xffffff), Option::None);
    }

    #[test]
    fn test_array_remove() {
        let mut array: Array<usize> = array![0, 2, 3, 4];
        let mut span: Span<usize> = array.span();
        // remove 2
        array = array.remove(@2);
        span = span.remove(@2).span();
        assert_eq!(array.len(), 3, "[removed 2]");
        assert_eq!(span.len(), 3, "[removed 2]");
        assert_eq!(*array[0], 0, "[removed 2]");
        assert_eq!(*array[1], 3, "[removed 2]");
        assert_eq!(*array[2], 4, "[removed 2]");
        assert_eq!(*span[0], 0, "[removed 2]");
        assert_eq!(*span[1], 3, "[removed 2]");
        assert_eq!(*span[2], 4, "[removed 2]");
        // remove non-existent
        array = array.remove(@2);
        span = span.remove(@2).span();
        assert_eq!(array.len(), 3, "[removed 2 again]");
        assert_eq!(span.len(), 3, "[removed 2 again]");
        assert_eq!(*array[0], 0, "[removed 2 again]");
        assert_eq!(*array[1], 3, "[removed 2 again]");
        assert_eq!(*array[2], 4, "[removed 2 again]");
        assert_eq!(*span[0], 0, "[removed 2 again]");
        assert_eq!(*span[1], 3, "[removed 2 again]");
        assert_eq!(*span[2], 4, "[removed 2 again]");
        // remove back
        array = array.remove(@4);
        span = span.remove(@4).span();
        assert_eq!(array.len(), 2, "[removed back]");
        assert_eq!(span.len(), 2, "[removed back]");
        assert_eq!(*array[0], 0, "[removed back]");
        assert_eq!(*array[1], 3, "[removed back]");
        assert_eq!(*span[0], 0, "[removed back]");
        assert_eq!(*span[1], 3, "[removed back]");
        // remove front
        array = array.remove(@0);
        span = span.remove(@0).span();
        assert_eq!(array.len(), 1, "[removed front]");
        assert_eq!(span.len(), 1, "[removed front]");
        assert_eq!(*array[0], 3, "[removed front]");
        assert_eq!(*span[0], 3, "[removed front]");
        // remove last
        array = array.remove(@3);
        span = span.remove(@3).span();
        assert_eq!(array.len(), 0, "[removed last]");
        assert_eq!(span.len(), 0, "[removed last]");
    }

}
