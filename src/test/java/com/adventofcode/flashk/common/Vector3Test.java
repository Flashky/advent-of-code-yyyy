package com.adventofcode.flashk.common;

import nl.jqno.equalsverifier.EqualsVerifier;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class Vector3Test {

    @Test
    void vector3Vector3Test() {
        Vector3 vector = new Vector3(3,-1,0);
        Vector3 copyVector = new Vector3(vector);

        assertEquals(3, copyVector.getX());
        assertEquals(-1, copyVector.getY());
        assertEquals(-0, copyVector.getZ());
    }

    @Test
    void vector3StringTest() {
        Vector3 vector = new Vector3("3,-1,0");

        assertEquals(3, vector.getX());
        assertEquals(-1, vector.getY());
        assertEquals(-0, vector.getZ());
    }

    @Test
    void testHashCodeAndEquals() {
        EqualsVerifier.simple()
                .forClass(Vector3.class)
                .verify();
    }

    @Test
    void transformTest() {

        Vector3 startPos = new Vector3(3,-1,0);
        Vector3 direction = new Vector3(2,3,-1);

        startPos.transform(direction);

        assertEquals(5, startPos.getX());
        assertEquals(2, startPos.getY());
        assertEquals(-1, startPos.getZ());
    }

    @Test
    void transformStaticTest() {

        Vector3 startPos = new Vector3(3,-1,0);
        Vector3 direction = new Vector3(2,3,-1);

        Vector3 endPos = Vector3.transform(startPos, direction);

        assertEquals(5, endPos.getX());
        assertEquals(2, endPos.getY());
        assertEquals(-1, endPos.getZ());

        // startPos has not been modified
        assertEquals(3, startPos.getX());
        assertEquals(-1, startPos.getY());
        assertEquals(-0, startPos.getZ());

        // direction has not been modified
        assertEquals(2, direction.getX());
        assertEquals(3, direction.getY());
        assertEquals(-1, direction.getZ());
    }

    @Test
    void testDistanceMainAxis() {

        // Arrange - X axis
        Vector3 a = new Vector3(0, 0, 0);
        Vector3 b = new Vector3(5, 0, 0);
        double expectedX = 5.0;

        // Act & Assert - X Axis
        double actualX = Vector3.distance(a, b);
        assertEquals(expectedX, actualX);

        // Arrange - Y axis
        a = new Vector3(1, 1, 1);
        b = new Vector3(1, 11, 1);
        double expectedY = 10.0;

        // Act & Assert - Y axis
        double actualY = Vector3.distance(a, b);
        assertEquals(expectedY, actualY);

        // Arrange - Z axis
        Vector3 v1 = new Vector3(2,5,8);
        Vector3 v2 = new Vector3(2,5,5);
        double expectedZ = 3;

        // Act & Assert - Z axis
        double actualZ = Vector3.distance(v1, v2);
        assertEquals(expectedZ, actualZ);
    }

    @Test
    void testDistance2D() {
        // 1. Arrange
        Vector3 a = new Vector3(0, 0, 0);
        Vector3 b = new Vector3(3, 4, 0);
        double expected = 5.0;

        // 2. Act
        double actual = Vector3.distance(a, b);

        // 3. Assert
        assertEquals(expected, actual);
    }

    @Test
    void testDistanceSame() {

        // 1. Arrange
        Vector3 a = new Vector3(100, 50, -25);
        Vector3 b = new Vector3(100, 50, -25);
        double expected = 0;

        // 2. Act
        double actual = Vector3.distance(a, b);

        // 3. Assert
        assertEquals(expected, actual);
    }

    @Test
    void testDistance() {
        // 1. Arrange
        Vector3 a = new Vector3(2, 8, 3);
        Vector3 b = new Vector3(7, 1, 9);

        double expected = Math.sqrt(110);

        // 2. Act
        double actual = Vector3.distance(a, b);

        // 3. Assert
        assertEquals(expected, actual);
    }

    @Test
    void testDistanceNegatives() {
        // 1. Arrange
        Vector3 a = new Vector3(1, 1, 1);
        Vector3 b = new Vector3(-3, -2, 7);
        double expected = Math.sqrt(61);

        // 2. Act
        double actual = Vector3.distance(a, b);

        // 3. Assert
        assertEquals(expected, actual);
    }

    @Test
    void leftTest() {

        Vector3 vector = Vector3.left();

        assertEquals(-1, vector.getX());
        assertEquals(0, vector.getY());
        assertEquals(0, vector.getZ());

    }

    @Test
    void rightTest() {

        Vector3 vector = Vector3.right();

        assertEquals(1, vector.getX());
        assertEquals(0, vector.getY());
        assertEquals(0, vector.getZ());

    }

    @Test
    void upTest() {

        Vector3 vector = Vector3.up();

        assertEquals(0, vector.getX());
        assertEquals(1, vector.getY());
        assertEquals(0, vector.getZ());
    }

    @Test
    void downTest() {
        Vector3 vector = Vector3.down();

        assertEquals(0, vector.getX());
        assertEquals(-1, vector.getY());
        assertEquals(0, vector.getZ());
    }

    @Test
    void forwardTest() {

        Vector3 vector = Vector3.forward();

        assertEquals(0, vector.getX());
        assertEquals(0, vector.getY());
        assertEquals(1, vector.getZ());

    }

    @Test
    void backward() {

        Vector3 vector = Vector3.backward();

        assertEquals(0, vector.getX());
        assertEquals(0, vector.getY());
        assertEquals(-1, vector.getZ());
    }
}