#ifndef UTIL_CONSTEXPR_MATH_HPP_
#define UTIL_CONSTEXPR_MATH_HPP_

#include <stddef.h>
#include <stdint.h>
#include <type_traits>

namespace util {



// Bit-shifting operator accepting negative shifts.
template <uint8_t bits, typename T>
static inline constexpr T rshift(T x) {
  static_assert(std::is_integral<T>::value, "Can't rshift a non-integral type");
  if constexpr (bits < 0) {
    return x << -bits;
  } else {
    return x >> bits;
  }
}



// Log base-2, plus one (floored).
template <typename T = size_t>
static inline constexpr uint8_t lgp1(T x) {
  static_assert(std::is_integral<T>::value, "Can't lgp1 a non-integral type");
  return x ? 1 + lgp1(x >> 1) : 0;
}



} // namespace util

#endif // UTIL_CONSTEXPR_MATH_HPP_
