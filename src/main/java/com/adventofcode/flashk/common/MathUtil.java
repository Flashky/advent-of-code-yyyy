package com.adventofcode.flashk.common;

import java.util.function.DoubleFunction;
import java.util.function.LongFunction;

public final class MathUtil {

	private MathUtil() {}
	
	/**
	 * Sums a number N times from i = number to i = 1. 
	 * <p>
	 * Example:
	 * </p>
	 * <pre>
	 * summation(0) = 0
	 * summation(1) = 1
	 * summation(2) = 2+1
	 * summation(3) = 3+2+1
	 * summation(n) = n+(n-1)+(n-2)+...+1
	 * </pre>
	 * @param value the number to apply summation
	 * @return the number summation. It will be 0 if input parameter is zero.
	 */
	public static long summation(long value) {
		
		if(value == 0) {
			return 0;
		}
		
		if(value == 1) {
			return 1;
		}
		
		return value + summation(value-1);
	}

    /**
     * Applies the sums of a function over a range of values.
     * Example:
     * <pre>
     *     summation(1, 5, i -> i * i) // returns 55 (1^2 + 2^2 + 3^2 + 4^2 + 5^2)
     *     summation(1, 5, i -> i) // returns 15 (1 + 2 + 3 + 4 + 5)
     *     summation(0, 0, i -> i) // returns 0 (0)
     * </pre>
     * @param min the minimum value to start the summation. Must be smaller or equal to max.
     * @param max the maximum value to end the summation. Must be greater or equal to min.
     * @param summationFunction the function to apply to each value in the range before summing them up.
     * @return the summation of the function applied to each value in the range
     * @throws IllegalArgumentException if min is greater than max
     */
    public static long summation(long min, long max, LongFunction<Long> summationFunction) {

        if(min > max) {
            throw new IllegalArgumentException("min must be less than or equal to max");
        }

        long sum = 0;

        for (long i = min; i <= max; i++) {
            sum += summationFunction.apply(i);
        }

        return sum;
    }

    /**
     * Applies the sums of a function over a range of values.
     * Example:
     * <pre>
     *     summation(1, 5, i -> i * i) // returns 55 (1^2 + 2^2 + 3^2 + 4^2 + 5^2)
     *     summation(1, 5, i -> i) // returns 15 (1 + 2 + 3 + 4 + 5)
     *     summation(0, 0, i -> i) // returns 0 (0)
     * </pre>
     * @param min the minimum value to start the summation. Must be smaller or equal to max.
     * @param max the maximum value to end the summation. Must be greater or equal to min.
     * @param summationFunction the function to apply to each value in the range before summing them up.
     * @return the summation of the function applied to each value in the range
     * @throws IllegalArgumentException if min is greater than max
     */
    public static double summation(double min, double max, DoubleFunction<Double> summationFunction) {

        if(min > max) {
            throw new IllegalArgumentException("min must be less than or equal to max");
        }

        double sum = 0;

        for (double i = min; i <= max; i++) {
            sum += summationFunction.apply(i);
        }

        return sum;
    }
}
