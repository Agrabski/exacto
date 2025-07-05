#![cfg_attr(not(test), no_std)]

use core::{
    cmp::Ordering,
    ops::{Add, Div, Mul, Neg, Sub},
};


#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Fraction<
    TNumber: Mul<Output = TNumber>
        + Div<Output = TNumber>
        + Add<Output = TNumber>
        + Sub<Output = TNumber>
        + Copy
        + PartialOrd
        + From<i32>
        + Neg<Output = TNumber>,
> {
    pub numerator: TNumber,
    pub denominator: TNumber,
}

impl<TNumber> Fraction<TNumber>
where
    TNumber: Mul<Output = TNumber>
        + Div<Output = TNumber>
        + Add<Output = TNumber>
        + Sub<Output = TNumber>
        + Copy
        + PartialOrd
        + From<i32>
        + Neg<Output = TNumber>,
{
    pub const fn new(numerator: TNumber, denominator: TNumber) -> Self {
        Self {
            numerator,
            denominator,
        }
    }

    pub fn reciprocal(&self) -> Self {
        assert!(
            self.numerator > TNumber::from(0),
            "Cannot take reciprocal of zero."
        );
        Self {
            numerator: self.denominator,
            denominator: self.numerator,
        }
    }

    pub fn zero() -> Self {
        Self {
            numerator: TNumber::from(0),
            denominator: TNumber::from(1),
        }
    }

    pub fn sqrt(&self) -> Self {
        if self.denominator == TNumber::from(0) {
            return Self::zero();
        }

        // Initial guess (good enough for most ranges)
        Self {
            denominator: slow_sqrt(self.denominator),
            numerator: slow_sqrt(self.numerator),
        }
    }

    pub fn abs(self) -> Self {
        let zero = TNumber::from(0);

        let mut num = self.numerator;
        let mut den = self.denominator;

        if num < zero {
            num = -num;
        }
        if den < zero {
            den = -den;
        }

        Self {
            numerator: num,
            denominator: den,
        }
    }

    pub fn value(&self) -> TNumber {
        self.numerator / self.denominator
    }
}

impl<TNumber> Neg for Fraction<TNumber>
where
    TNumber: Mul<Output = TNumber>
        + Div<Output = TNumber>
        + Add<Output = TNumber>
        + Sub<Output = TNumber>
        + Copy
        + PartialOrd
        + From<i32>
        + Neg<Output = TNumber>,
{
    type Output = Fraction<TNumber>;

    fn neg(self) -> Self::Output {
        Self {
            numerator: -self.numerator,
            denominator: self.denominator,
        }
    }
}

// Implement multiplication for Fractions
impl<TNumber> Mul for Fraction<TNumber>
where
    TNumber: Mul<Output = TNumber>
        + Div<Output = TNumber>
        + Add<Output = TNumber>
        + Sub<Output = TNumber>
        + Copy
        + PartialOrd
        + From<i32>
        + Neg<Output = TNumber>,
{
    type Output = Self;

    fn mul(self, rhs: Self) -> Self::Output {
        Self {
            numerator: self.numerator * rhs.numerator,
            denominator: self.denominator * rhs.denominator,
        }
    }
}

impl<TNumber> Div for Fraction<TNumber>
where
    TNumber: Mul<Output = TNumber>
        + Div<Output = TNumber>
        + Add<Output = TNumber>
        + Sub<Output = TNumber>
        + Copy
        + PartialOrd
        + From<i32>
        + Neg<Output = TNumber>,
{
    type Output = Self;

    fn div(self, rhs: Self) -> Self::Output {
        assert!(rhs.numerator > TNumber::from(0), "Cannot divide by zero.");
        Self {
            numerator: self.numerator * rhs.denominator,
            denominator: self.denominator * rhs.numerator,
        }
    }
}

impl<TNumber> PartialOrd for Fraction<TNumber>
where
    TNumber: Mul<Output = TNumber>
        + Div<Output = TNumber>
        + Add<Output = TNumber>
        + Sub<Output = TNumber>
        + Copy
        + PartialOrd
        + From<i32>
        + Neg<Output = TNumber>,
{
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        let lhs = self.numerator * other.denominator;
        let rhs = other.numerator * self.denominator;
        lhs.partial_cmp(&rhs)
    }
}

impl<TNumber> From<TNumber> for Fraction<TNumber>
where
    TNumber: Mul<Output = TNumber>
        + Div<Output = TNumber>
        + Add<Output = TNumber>
        + Sub<Output = TNumber>
        + Copy
        + PartialOrd
        + From<i32>
        + Neg<Output = TNumber>,
{
    fn from(value: TNumber) -> Self {
        Self::new(value, TNumber::from(1))
    }
}

impl<TNumber> Add for Fraction<TNumber>
where
    TNumber: Mul<Output = TNumber>
        + Div<Output = TNumber>
        + Add<Output = TNumber>
        + Sub<Output = TNumber>
        + Copy
        + PartialOrd
        + From<i32>
        + Neg<Output = TNumber>,
{
    type Output = Self;

    fn add(self, rhs: Self) -> Self::Output {
        let lhs_num = self.numerator * rhs.denominator;
        let rhs_num = rhs.numerator * self.denominator;
        let new_num = lhs_num + rhs_num;
        let new_den = self.denominator * rhs.denominator;

        Self {
            numerator: new_num,
            denominator: new_den,
        }
    }
}

impl<TNumber> Add<TNumber> for Fraction<TNumber>
where
    TNumber: Mul<Output = TNumber>
        + Div<Output = TNumber>
        + Add<Output = TNumber>
        + Sub<Output = TNumber>
        + Copy
        + PartialOrd
        + From<i32>
        + Neg<Output = TNumber>,
{
    type Output = Self;

    fn add(self, rhs: TNumber) -> Self::Output {
        let rhs_frac = Fraction {
            numerator: rhs,
            denominator: TNumber::from(1),
        };
        self + rhs_frac
    }
}

fn slow_sqrt<TNumber>(value: TNumber) -> TNumber
where
    TNumber: Mul<Output = TNumber>
        + Div<Output = TNumber>
        + Add<Output = TNumber>
        + Sub<Output = TNumber>
        + Copy
        + PartialOrd
        + From<i32>
        + Neg<Output = TNumber>,
{
    // Brute-force sqrt for integer-like types without Step trait
    let mut x = TNumber::from(0);
    let one = TNumber::from(1);
    while x * x <= value {
        x = x + one;
    }
    x - one
}

impl<TNumber> Div<TNumber> for Fraction<TNumber>
where
    TNumber: Mul<Output = TNumber>
        + Div<Output = TNumber>
        + Add<Output = TNumber>
        + Sub<Output = TNumber>
        + Copy
        + PartialOrd
        + From<i32>
        + Neg<Output = TNumber>,
{
    type Output = Self;

    fn div(self, rhs: TNumber) -> Self::Output {
        Self {
            numerator: self.numerator,
            denominator: self.denominator * rhs,
        }
    }
}
impl<TNumber> Sub for Fraction<TNumber>
where
    TNumber: Mul<Output = TNumber>
        + Div<Output = TNumber>
        + Add<Output = TNumber>
        + Sub<Output = TNumber>
        + Copy
        + PartialOrd
        + From<i32>
        + Neg<Output = TNumber>,
{
    type Output = Self;

    fn sub(self, rhs: Self) -> Self::Output {
        let lhs_num = self.numerator * rhs.denominator;
        let rhs_num = rhs.numerator * self.denominator;
        let new_num = lhs_num - rhs_num;
        let new_den = self.denominator * rhs.denominator;

        Self {
            numerator: new_num,
            denominator: new_den,
        }
    }
}
impl<TNumber> Eq for Fraction<TNumber> where
    TNumber: Eq
        + Copy
        + Mul<Output = TNumber>
        + Mul<Output = TNumber>
        + Div<Output = TNumber>
        + Add<Output = TNumber>
        + Sub<Output = TNumber>
        + Copy
        + PartialOrd
        + From<i32>
        + Neg<Output = TNumber>
{
}

// --- Ord ---
impl<TNumber> Ord for Fraction<TNumber>
where
    TNumber: Ord
        + Copy
        + Mul<Output = TNumber>
        + Mul<Output = TNumber>
        + Div<Output = TNumber>
        + Add<Output = TNumber>
        + Sub<Output = TNumber>
        + Copy
        + PartialOrd
        + From<i32>
        + Neg<Output = TNumber>,
{
    fn cmp(&self, other: &Self) -> Ordering {
        let lhs = self.numerator * other.denominator;
        let rhs = other.numerator * self.denominator;
        lhs.cmp(&rhs)
    }
}

#[cfg(test)]
mod tests {
    #[test]
    fn test_f() {

    }
}
