#![cfg_attr(not(test), no_std)]
use core::fmt::Display;
use core::{
    cmp::Ordering,
    ops::{Add, Div, Mul, Neg, Sub},
};
use num::traits::{SaturatingAdd, SaturatingMul, SaturatingSub};
use num::Bounded;

pub trait Integer:
    num::Integer + num::Signed + Copy + SaturatingMul + Bounded + SaturatingAdd + SaturatingSub + Display + SqrtOfMax
{
}

pub trait SqrtOfMax {
    const SQRT: Self;
}

impl SqrtOfMax for i32 {
    const SQRT: Self = 46340;
}

impl SqrtOfMax for i16 {
    const SQRT: Self = 181;
}

impl<T: num::Integer + num::Signed + Copy + SaturatingMul + Bounded + SaturatingAdd + SaturatingSub + Display + SqrtOfMax>
    Integer for T
{
}

// Reduce fraction by their GCD if possible
fn gcd<TNumber: Integer>(mut a: TNumber, mut b: TNumber) -> TNumber {
    while b != TNumber::zero() {
        let tmp = b;
        b = a % b;
        a = tmp;
    }
    assert!(a != TNumber::zero());
    // The Euclidean loop can leave `a` negative when the inputs are negative
    // (`%` keeps the sign of the dividend). Always return a positive divisor so
    // callers can divide either operand by it without flipping its sign.
    if a < TNumber::zero() {
        safe_neg(a)
    } else {
        a
    }
}

#[derive(Debug, Clone, Copy)]
pub struct Fraction<TNumber: Integer> {
    pub numerator: TNumber,
    pub denominator: TNumber,
}

impl<TNumber> Fraction<TNumber>
where
    TNumber: Integer,
{
    pub const fn new(numerator: TNumber, denominator: TNumber) -> Self {
        Self {
            numerator,
            denominator,
        }
    }

    pub fn reciprocal(&self) -> Self {
        assert!(
            self.numerator != TNumber::zero(),
            "Cannot take reciprocal of zero."
        );
        Self {
            numerator: self.denominator,
            denominator: self.numerator,
        }
    }

    pub fn zero() -> Self {
        Self {
            numerator: TNumber::zero(),
            denominator: TNumber::one(),
        }
    }

    pub fn sqrt(&self) -> Self {
        // Normalize first so the sign lives in the numerator and the
        // denominator is positive; `slow_sqrt` is only meaningful on
        // non-negative values.
        let normalized = self.normalized();
        assert!(
            normalized.numerator >= TNumber::zero(),
            "Cannot take the square root of a negative fraction."
        );

        if normalized.numerator == TNumber::zero() {
            return Self::zero();
        }

        Self {
            denominator: slow_sqrt(normalized.denominator),
            numerator: slow_sqrt(normalized.numerator),
        }
    }

    pub fn abs(self) -> Self {
        let zero = TNumber::zero();

        let mut num = self.numerator;
        let mut den = self.denominator;

        if num < zero {
            num = safe_neg(num);
        }
        if den < zero {
            den = safe_neg(den);
        }

        Self {
            numerator: num,
            denominator: den,
        }
    }

    pub fn value(&self) -> TNumber {
        assert!(
            self.denominator != TNumber::zero(),
            "Cannot evaluate a fraction with a zero denominator."
        );
        // Normalizing forces a positive denominator, which avoids the
        // `MIN / -1` overflow that a raw division would hit on an
        // un-normalized fraction with a negative denominator.
        let normalized = self.normalized();
        normalized.numerator / normalized.denominator
    }

    pub fn normalized(&self) -> Self {
        let zero = TNumber::zero();
        let one = TNumber::one();

        // A zero numerator is canonically 0/1. Handling it up front keeps
        // `gcd` from being called with a zero argument (which would trip its
        // assertion for the 0/0 case) and avoids depending on the denominator.
        if self.numerator == zero {
            return Self::zero();
        }

        let mut num = self.numerator;
        let mut den = self.denominator;

        // Move sign to numerator, denominator always positive
        if den < zero {
            num = safe_neg(num);
            den = safe_neg(den)
        }

        // `gcd` returns a positive divisor, so the sign is preserved and a
        // divisor of 1 (the only case that could trigger a `MIN / -1`
        // overflow) is skipped entirely.
        let reduced = {
            let divisor = gcd(num, den);

            if divisor != one {
                (num / divisor, den / divisor)
            } else {
                (num, den)
            }
        };

        Self {
            numerator: reduced.0,
            denominator: reduced.1,
        }
    }
}

impl<TNumber> Neg for Fraction<TNumber>
where
    TNumber: Integer,
{
    type Output = Fraction<TNumber>;

    fn neg(self) -> Self::Output {
        Self {
            // `safe_neg` keeps `MIN` from overflowing, matching `abs`.
            numerator: safe_neg(self.numerator),
            denominator: self.denominator,
        }
    }
}

impl<TNumber> Mul for Fraction<TNumber>
where
    TNumber: Integer,
{
    type Output = Self;

    fn mul(self, rhs: Self) -> Self::Output {
        let a = self.normalized();
        let b = rhs.normalized();

        // Cancel common factors across the cross terms *before* multiplying so
        // representable results don't saturate just because the intermediate
        // products would have overflowed.
        let g1 = gcd(a.numerator, b.denominator);
        let g2 = gcd(b.numerator, a.denominator);

        Self {
            numerator: (a.numerator / g1).saturating_mul(&(b.numerator / g2)),
            denominator: (a.denominator / g2).saturating_mul(&(b.denominator / g1)),
        }
        .normalized()
    }
}

impl<TNumber> Div for Fraction<TNumber>
where
    TNumber: Integer,
{
    type Output = Self;

    fn div(self, rhs: Self) -> Self::Output {
        // Only a zero numerator is an invalid divisor; negative divisors are
        // perfectly fine.
        assert!(rhs.numerator != TNumber::zero(), "Cannot divide by zero.");
        let a = self.normalized();
        let b = rhs.normalized();

        // a/b = (a.num * b.den) / (a.den * b.num); cancel the cross terms first
        // to keep representable results from saturating.
        let g1 = gcd(a.numerator, b.numerator);
        let g2 = gcd(a.denominator, b.denominator);

        Self {
            numerator: (a.numerator / g1).saturating_mul(&(b.denominator / g2)),
            denominator: (a.denominator / g2).saturating_mul(&(b.numerator / g1)),
        }
        .normalized()
    }
}

impl<TNumber> PartialOrd for Fraction<TNumber>
where
    TNumber: Integer,
{
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

impl<TNumber> PartialEq for Fraction<TNumber>
where
    TNumber: Integer,
{
    fn eq(&self, other: &Self) -> bool {
        // Compare by value so that, e.g., 6/12 and 1/2 are equal and `Eq`
        // stays consistent with `Ord`.
        self.cmp(other) == Ordering::Equal
    }
}

impl<TNumber> From<TNumber> for Fraction<TNumber>
where
    TNumber: Integer,
{
    fn from(value: TNumber) -> Self {
        Self::new(value, TNumber::one())
    }
}

impl<TNumber> Add for Fraction<TNumber>
where
    TNumber: Integer,
{
    type Output = Self;

    fn add(self, rhs: Self) -> Self::Output {
        let a = self.normalized();
        let b = rhs.normalized();

        // Use the least common denominator (a.den / g * b.den) instead of the
        // full product so the denominator only grows by the factor it must.
        let g = gcd(a.denominator, b.denominator);
        let a_factor = b.denominator / g;
        let b_factor = a.denominator / g;

        let lhs_num = a.numerator.saturating_mul(&a_factor);
        let rhs_num = b.numerator.saturating_mul(&b_factor);
        let new_num = lhs_num.saturating_add(&rhs_num);
        let new_den = a.denominator.saturating_mul(&a_factor);

        Self {
            numerator: new_num,
            denominator: new_den,
        }
        .normalized()
    }
}

impl<TNumber> Add<TNumber> for Fraction<TNumber>
where
    TNumber: Integer,
{
    type Output = Self;

    fn add(self, rhs: TNumber) -> Self::Output {
        let rhs_frac = Fraction {
            numerator: rhs,
            denominator: TNumber::one(),
        };
        self + rhs_frac
    }
}

fn slow_sqrt<TNumber>(value: TNumber) -> TNumber
where
    TNumber: Integer,
{
    if value == TNumber::max_value() {
        return TNumber::SQRT;
    }
    let one = TNumber::one();
    let two = one + one;
    // 0 and 1 are their own floor-sqrt; also avoids dividing by zero below.
    if value < two {
        return value;
    }
    // Newton's method for floor(sqrt(value)). Converges in O(log value)
    // iterations using only add/div, so it stays cheap on an FPU-less AVR.
    // The max_value guard above keeps `value + one` from overflowing.
    let mut x = value;
    let mut y = (value + one) / two;
    while y < x {
        x = y;
        y = (x + value / x) / two;
    }
    x
}

impl<TNumber> Div<TNumber> for Fraction<TNumber>
where
    TNumber: Integer,
{
    type Output = Self;

    fn div(self, rhs: TNumber) -> Self::Output {
        assert!(rhs != TNumber::zero(), "Cannot divide by zero.");
        Self {
            numerator: self.numerator,
            denominator: self.denominator.saturating_mul(&rhs),
        }
        .normalized()
    }
}
impl<TNumber> Sub for Fraction<TNumber>
where
    TNumber: Integer,
{
    type Output = Self;

    fn sub(self, rhs: Self) -> Self::Output {
        let a = self.normalized();
        let b = rhs.normalized();

        let g = gcd(a.denominator, b.denominator);
        let a_factor = b.denominator / g;
        let b_factor = a.denominator / g;

        let lhs_num = a.numerator.saturating_mul(&a_factor);
        let rhs_num = b.numerator.saturating_mul(&b_factor);
        let new_num = lhs_num.saturating_sub(&rhs_num);
        let new_den = a.denominator.saturating_mul(&a_factor);

        Self {
            numerator: new_num,
            denominator: new_den,
        }
        .normalized()
    }
}
impl<TNumber> Eq for Fraction<TNumber> where TNumber: Integer {}

// --- Ord ---
impl<TNumber> Ord for Fraction<TNumber>
where
    TNumber: Integer,
{
    fn cmp(&self, other: &Self) -> Ordering {
        // Normalize so both denominators are positive, then compare without
        // ever multiplying (see `cmp_frac`) so the ordering can't be lost to
        // saturation.
        let a = self.normalized();
        let b = other.normalized();
        cmp_frac(a.numerator, a.denominator, b.numerator, b.denominator)
    }
}

/// Compares `n1/d1` against `n2/d2` for strictly positive denominators using a
/// continued-fraction expansion. It only ever takes floor-divisions and
/// remainders of the running operands, so no intermediate ever overflows and
/// the result is always exact.
fn cmp_frac<TNumber: Integer>(
    mut n1: TNumber,
    mut d1: TNumber,
    mut n2: TNumber,
    mut d2: TNumber,
) -> Ordering {
    let zero = TNumber::zero();
    loop {
        let q1 = n1.div_floor(&d1);
        let q2 = n2.div_floor(&d2);
        if q1 != q2 {
            return q1.cmp(&q2);
        }

        let r1 = n1.mod_floor(&d1);
        let r2 = n2.mod_floor(&d2);
        match (r1 == zero, r2 == zero) {
            (true, true) => return Ordering::Equal,
            (true, false) => return Ordering::Less,
            (false, true) => return Ordering::Greater,
            (false, false) => {
                // Integer parts match, so compare the fractional parts
                // r1/d1 vs r2/d2. Taking reciprocals flips the order, so on the
                // next pass we compare d2/r2 vs d1/r1 (operands swapped), whose
                // result equals cmp(r1/d1, r2/d2). Both new denominators
                // (r1, r2) are strictly positive, preserving the invariant.
                let (next_n1, next_d1, next_n2, next_d2) = (d2, r2, d1, r1);
                n1 = next_n1;
                d1 = next_d1;
                n2 = next_n2;
                d2 = next_d2;
            }
        }
    }
}

fn safe_neg<TNumber: Integer>(value: TNumber) -> TNumber {
    if value == TNumber::min_value() {
        TNumber::max_value()
    } else if value == TNumber::max_value() {
        TNumber::min_value()
    } else {
        -value
    }
}

#[cfg(test)]
mod tests {
    use crate::slow_sqrt;

    type Fraction = super::Fraction<i32>;

    #[test]
    fn test_new_and_value() {
        let f = Fraction::new(3, 4);
        assert_eq!(f.numerator, 3);
        assert_eq!(f.denominator, 4);
        assert_eq!(f.value(), 3 / 4);
    }

    #[test]
    fn test_add_fraction() {
        let a = Fraction::new(1, 2);
        let b = Fraction::new(1, 3);
        let result = a + b;
        assert_eq!(result.numerator, 5);
        assert_eq!(result.denominator, 6);
    }

    #[test]
    fn test_add_number() {
        let a = Fraction::new(3, 4);
        let result = a + 1;
        assert_eq!(result.numerator, 7);
        assert_eq!(result.denominator, 4);
    }

    #[test]
    fn test_sub_fraction() {
        let a = Fraction::new(3, 4);
        let b = Fraction::new(1, 4);
        let result = a - b;
        assert_eq!(result, Fraction::new(1, 2));
    }

    #[test]
    fn test_mul_fraction() {
        let a = Fraction::new(2, 3);
        let b = Fraction::new(3, 4);
        let result = a * b;
        assert_eq!(result, Fraction::new(6, 12).normalized());
    }

    #[test]
    fn test_div_fraction() {
        let a = Fraction::new(2, 3);
        let b = Fraction::new(4, 5);
        let result = a / b;
        assert_eq!(result, Fraction::new(10, 12).normalized());
    }

    #[test]
    fn one_divided_by_one_is_one() {
        let a = Fraction::new(1, 1);
        let b = Fraction::new(1, 1);
        let result = a / b;
        assert_eq!(result, Fraction::new(1, 1));
    }

    #[test]
    fn test_div_number() {
        let a = Fraction::new(3, 4);
        let result = a / 2;
        assert_eq!(result.numerator, 3);
        assert_eq!(result.denominator, 8);
    }

    #[test]
    fn test_neg() {
        let a = Fraction::new(3, 4);
        let result = -a;
        assert_eq!(result.numerator, -3);
        assert_eq!(result.denominator, 4);
    }

    #[test]
    fn test_abs() {
        let a = Fraction::new(-3, -4);
        let result = a.abs();
        assert_eq!(result.numerator, 3);
        assert_eq!(result.denominator, 4);
    }

    #[test]
    fn test_reciprocal() {
        let a = Fraction::new(2, 3);
        let result = a.reciprocal();
        assert_eq!(result.numerator, 3);
        assert_eq!(result.denominator, 2);
    }

    #[test]
    #[should_panic]
    fn test_reciprocal_zero() {
        let a = Fraction::new(0, 1);
        let _ = a.reciprocal();
    }

    #[test]
    fn test_zero() {
        let z = Fraction::zero();
        assert_eq!(z.numerator, 0);
        assert_eq!(z.denominator, 1);
    }

    #[test]
    fn test_partial_ord() {
        let a = Fraction::new(1, 2);
        let b = Fraction::new(2, 3);
        assert!(a < b);
        assert!(b > a);
        assert_eq!(a.partial_cmp(&a), Some(core::cmp::Ordering::Equal));
    }

    #[test]
    fn test_ord() {
        let a = Fraction::new(1, 2);
        let b = Fraction::new(2, 3);
        assert!(a < b);
        assert!(b > a);
        assert_eq!(a.cmp(&a), core::cmp::Ordering::Equal);
    }

    #[test]
    fn test_from_number() {
        let f = Fraction::from(5);
        assert_eq!(f.numerator, 5);
        assert_eq!(f.denominator, 1);
    }

    #[test]
    fn test_sqrt() {
        let a = Fraction::new(9, 16);
        let result = a.sqrt();
        assert_eq!(result.numerator, 3);
        assert_eq!(result.denominator, 4);
    }

    #[test]
    fn test_sqrt_32767() {
        let result = slow_sqrt(32767i16);
        assert_eq!(result, 181);
    }

    #[test]
    fn test_slow_sqrt_i32_floor() {
        assert_eq!(slow_sqrt(0i32), 0);
        assert_eq!(slow_sqrt(1i32), 1);
        assert_eq!(slow_sqrt(2i32), 1);
        assert_eq!(slow_sqrt(15i32), 3);
        assert_eq!(slow_sqrt(16i32), 4);
        assert_eq!(slow_sqrt(1_000_000i32), 1000);
        // 46340^2 = 2_147_395_600 <= i32::MAX < 46341^2
        assert_eq!(slow_sqrt(2_147_395_600i32), 46340);
        assert_eq!(slow_sqrt(i32::MAX - 1), 46340);
        assert_eq!(slow_sqrt(i32::MAX), 46340);
    }

    #[test]
    fn test_ord_no_overflow_large_i32() {
        // Cross-multiplying these naively overflows i32; saturating mul must
        // still order them correctly.
        let a = Fraction::new(100_000, 1);
        let b = Fraction::new(200_000, 1);
        assert!(a < b);
        assert!(b > a);
    }

    // --- Issue 1: Neg overflow on MIN ---
    #[test]
    fn test_neg_min_does_not_overflow() {
        let a = Fraction::new(i32::MIN, 1);
        let result = -a;
        // safe_neg saturates MIN to MAX rather than overflowing.
        assert_eq!(result.numerator, i32::MAX);
        assert_eq!(result.denominator, 1);
    }

    // --- Issue 2: reciprocal / div reject only zero, not negatives ---
    #[test]
    fn test_reciprocal_of_negative() {
        let a = Fraction::new(-2, 3);
        let result = a.reciprocal();
        assert_eq!(result, Fraction::new(-3, 2));
    }

    #[test]
    fn test_div_by_negative_fraction() {
        let a = Fraction::new(1, 2);
        let b = Fraction::new(-1, 3);
        let result = a / b;
        assert_eq!(result, Fraction::new(-3, 2));
    }

    // --- Issue 3: value() on a negative denominator must not overflow ---
    #[test]
    fn test_value_min_over_neg_one_does_not_overflow() {
        let a = Fraction::new(i32::MIN, -1);
        // True value (2_147_483_648) is out of range; saturating to MAX is the
        // expected behaviour, and crucially this must not panic.
        assert_eq!(a.value(), i32::MAX);
    }

    #[test]
    #[should_panic]
    fn test_value_zero_denominator_panics() {
        let a = Fraction::new(1, 0);
        let _ = a.value();
    }

    // --- Issue 4: dividing by the integer zero must be rejected ---
    #[test]
    #[should_panic]
    fn test_div_by_integer_zero_panics() {
        let a = Fraction::new(1, 2);
        let _ = a / 0;
    }

    #[test]
    #[should_panic]
    fn test_div_by_fraction_zero_panics() {
        let a = Fraction::new(1, 2);
        let _ = a / Fraction::new(0, 5);
    }

    // --- Issue 5: normalizing 0/0 must not panic ---
    #[test]
    fn test_normalize_zero_over_zero() {
        let a = Fraction::new(0, 0);
        assert_eq!(a.normalized(), Fraction::zero());
    }

    // --- gcd sign: normalized must keep a positive denominator ---
    #[test]
    fn test_normalize_negative_keeps_positive_denominator() {
        let a = Fraction::new(-6, 4).normalized();
        assert_eq!(a.numerator, -3);
        assert_eq!(a.denominator, 2);
        assert!(a.denominator > 0);
    }

    #[test]
    fn test_normalize_negative_denominator() {
        let a = Fraction::new(6, -4).normalized();
        assert_eq!(a.numerator, -3);
        assert_eq!(a.denominator, 2);
    }

    // --- Issue 6: arithmetic must not saturate on representable results ---
    #[test]
    fn test_mul_no_spurious_saturation() {
        // Naive cross-multiply: 50000*60000 = 3e9 overflows i32, so a
        // saturating product would give the wrong answer. True value is 3/2.
        let a = Fraction::new(50_000, 40_000);
        let b = Fraction::new(60_000, 50_000);
        assert_eq!(a * b, Fraction::new(3, 2));
    }

    #[test]
    fn test_add_no_spurious_saturation() {
        // Naive common denominator 50000*50000 overflows; LCM keeps it at 50000.
        let a = Fraction::new(1, 50_000);
        let b = Fraction::new(1, 50_000);
        assert_eq!(a + b, Fraction::new(1, 25_000));
    }

    #[test]
    fn test_div_no_spurious_saturation() {
        // (50000/40000) / (60000/50000) = 25/24 ... cross terms overflow naively.
        let a = Fraction::new(50_000, 40_000);
        let b = Fraction::new(60_000, 50_000);
        assert_eq!(a / b, Fraction::new(25, 24));
    }

    // --- Issue 7: comparison must not collapse to Equal under saturation ---
    #[test]
    fn test_cmp_no_spurious_equal() {
        // Both cross-products (50000*50000 and 47000*48000) saturate to i32::MAX
        // with the old approach, yielding a false Equal. a (~1.04) > b (~0.94).
        let a = Fraction::new(50_000, 48_000);
        let b = Fraction::new(47_000, 50_000);
        assert!(a > b);
        assert!(b < a);
        assert_ne!(a, b);
    }

    // --- Issue 8: comparison must respect a negative denominator ---
    #[test]
    fn test_cmp_negative_denominator() {
        let a = Fraction::new(1, -2); // -0.5
        let b = Fraction::new(1, 2); //  0.5
        assert!(a < b);
        assert!(b > a);
    }

    // --- Eq must agree with Ord (value equality) ---
    #[test]
    fn test_eq_is_by_value() {
        assert_eq!(Fraction::new(6, 12), Fraction::new(1, 2));
        assert_eq!(Fraction::new(-1, -2), Fraction::new(1, 2));
        assert_ne!(Fraction::new(1, 2), Fraction::new(1, 3));
    }

    // --- sqrt of a negative fraction must panic, not return garbage ---
    #[test]
    #[should_panic]
    fn test_sqrt_negative_panics() {
        let a = Fraction::new(-9, 16);
        let _ = a.sqrt();
    }
}
