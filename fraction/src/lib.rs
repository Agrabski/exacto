#![cfg_attr(not(test), no_std)]
use core::fmt::Display;
use core::{
    cmp::Ordering,
    ops::{Add, Div, Mul, Neg, Sub},
};
use num::traits::{SaturatingAdd, SaturatingMul};
use num::Bounded;

pub trait Integer:
    num::Integer + num::Signed + Copy + SaturatingMul + Bounded + SaturatingAdd + Display + SqrtOfMax
{
}

pub trait SqrtOfMax {
    const SQRT: Self;
}

impl SqrtOfMax for u8 {
    const SQRT: Self = 16;
}

impl SqrtOfMax for u16 {
    const SQRT: Self = 256;
}

impl SqrtOfMax for u32 {
    const SQRT: Self = 65536;
}

impl SqrtOfMax for i32 {
    const SQRT: Self = 32761;
}

impl SqrtOfMax for i16 {
    const SQRT: Self = 181;
}

impl<T: num::Integer + num::Signed + Copy + SaturatingMul + Bounded + SaturatingAdd + Display + SqrtOfMax>
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
    a
}

#[derive(Debug, Clone, Copy, PartialEq)]
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
            self.numerator > TNumber::zero(),
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
        if self.numerator == TNumber::zero() {
            return Self::zero();
        }

        // Initial guess (good enough for most ranges)
        Self {
            denominator: slow_sqrt(self.denominator),
            numerator: slow_sqrt(self.numerator),
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
        self.numerator / self.denominator
    }

    pub fn normalized(&self) -> Self {
        let zero = TNumber::zero();
        let one = TNumber::one();

        let mut num = self.numerator;
        let mut den = self.denominator;

        // Move sign to numerator, denominator always positive
        if den < zero {
            num = safe_neg(num);
            den = safe_neg(den)
        }

        // Only try to reduce if TNumber supports remainder
        let reduced = {
            let divisor = gcd(num, den);

            if divisor.abs() != one {
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
            numerator: -self.numerator,
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
        Self {
            numerator: self.numerator.saturating_mul(&rhs.numerator),
            denominator: self.denominator.saturating_mul(&rhs.denominator),
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
        assert!(rhs.numerator > TNumber::zero(), "Cannot divide by zero.");
        Self {
            numerator: self.numerator.saturating_mul(&rhs.denominator),
            denominator: self.denominator.saturating_mul(&rhs.numerator),
        }
        .normalized()
    }
}

impl<TNumber> PartialOrd for Fraction<TNumber>
where
    TNumber: Integer,
{
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        let lhs = self.numerator * other.denominator;
        let rhs = other.numerator * self.denominator;
        lhs.partial_cmp(&rhs)
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
        let lhs_num = self.numerator.saturating_mul(&rhs.denominator);
        let rhs_num = rhs.numerator.saturating_mul(&self.denominator);
        let new_num = lhs_num.saturating_add(&rhs_num);
        let new_den = self.denominator.saturating_mul(&rhs.denominator);

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
        (self + rhs_frac).normalized()
    }
}

fn slow_sqrt<TNumber>(value: TNumber) -> TNumber
where
    TNumber: Integer,
{
    if value == TNumber::max_value() {
        return TNumber::SQRT;
    }
    // Brute-force sqrt for integer-like types without Step trait
    let mut x = TNumber::zero();
    let one = TNumber::one();
    let mut square =x.saturating_mul(&x);
    while square  <= value {
        x = x + one;
        square =x.saturating_mul(&x);
    }
    x - one
}

impl<TNumber> Div<TNumber> for Fraction<TNumber>
where
    TNumber: Integer,
{
    type Output = Self;

    fn div(self, rhs: TNumber) -> Self::Output {
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
        let lhs_num = self.numerator.saturating_mul(&rhs.denominator);
        let rhs_num = rhs.numerator.saturating_mul(&self.denominator);
        let new_num = lhs_num - rhs_num;
        let new_den = self.denominator.saturating_mul(&rhs.denominator);

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
    TNumber: Ord + Copy + Mul<Output = TNumber> + Integer,
{
    fn cmp(&self, other: &Self) -> Ordering {
        let lhs = self.numerator * other.denominator;
        let rhs = other.numerator * self.denominator;
        lhs.cmp(&rhs)
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
}
