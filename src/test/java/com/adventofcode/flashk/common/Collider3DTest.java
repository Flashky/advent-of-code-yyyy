package com.adventofcode.flashk.common;

import module java.base;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class Collider3DTest {

    @Test
    void testSinglePointConstructorInitialization() {
        // Given a single point
        Vector3 point = new Vector3(10, -5, 20);

        // When creating a collider from that point
        Collider3D collider = new Collider3D(point);

        // Then all bounds must be equal to the point's coordinates
        assertEquals(10, collider.getMinX());
        assertEquals(10, collider.getMaxX());
        assertEquals(-5, collider.getMinY());
        assertEquals(-5, collider.getMaxY());
        assertEquals(20, collider.getMinZ());
        assertEquals(20, collider.getMaxZ());
    }

    @Test
    void testConstructorDefensiveCopy() {
        // Given a vector
        Vector3 start = new Vector3(0, 0, 0);
        Vector3 end = new Vector3(1, 1, 1);

        // When creating the collider
        Collider3D collider = new Collider3D(start, end);

        // And then modifying the original vectors externally
        start.transform(new Vector3(10, 10, 10));

        // Then the collider bounds must remain unchanged (defensive copy)
        assertEquals(0, collider.getMinX(), "Collider should be immune to external vector modifications");
        assertEquals(0, collider.getMinY());
        assertEquals(0, collider.getMinZ());
    }

    @Test
    void testConstructorWithInvertedPoints() {
        // Given start is "greater" than end
        Vector3 start = new Vector3(10, 10, 10);
        Vector3 end = new Vector3(0, 0, 0);

        // When creating the collider
        Collider3D collider = new Collider3D(start, end);

        // Then min/max must be correctly normalized
        assertEquals(0, collider.getMinX());
        assertEquals(10, collider.getMaxX());
        assertEquals(0, collider.getMinY());
        assertEquals(10, collider.getMaxY());
        assertEquals(0, collider.getMinZ());
        assertEquals(10, collider.getMaxZ());
    }

    @Test
    void testCopyConstructor() {
        // Given an original collider
        Vector3 start = new Vector3(0, 0, 0);
        Vector3 end = new Vector3(10, 10, 10);
        Collider3D original = new Collider3D(start, end);

        // When creating a copy
        Collider3D copy = new Collider3D(original);

        // Then both must be equal in values
        assertEquals(original.getMinX(), copy.getMinX());
        assertEquals(original.getMaxZ(), copy.getMaxZ());
        assertEquals(original, copy, "The copy should be equal to the original");

        // And when transforming the copy
        copy.transform(new Vector3(5, 5, 5));

        // Then the original must remain unchanged (deep copy)
        assertNotEquals(original.getMinX(), copy.getMinX(), "Transforming the copy should not affect the original");
        assertEquals(0, original.getMinX(), "Original minX should still be 0");
        assertEquals(5, copy.getMinX(), "Copy minX should now be 5");
    }

    @Test
    void testIdenticalObjectsCollide() {
        // Two 1x1x1 cubes at the same position must collide
        Vector3 pos = new Vector3(2, 2, 2);
        Collider3D a = new Collider3D(pos, pos);
        Collider3D b = new Collider3D(pos, pos);

        assertTrue(a.collidesWith(b), "Identical objects must collide");
    }

    @Test
    void testBrickHorizontalOverlap() {
        // Horizontal collider (0,0,10 to 1,0,10) with volume 2
        Collider3D horizontal = new Collider3D(new Vector3(0, 0, 10), new Vector3(1, 0, 10));

        // A single cube occupies one of the colliders cells (1,0,10)
        Vector3 cubePos = new Vector3(1, 0, 10);
        Collider3D cube = new Collider3D(cubePos, cubePos);

        assertTrue(horizontal.collidesWith(cube), "The cube must collide with the edge of the horizontal brick");
    }

    @Test
    void testBrickVerticalCollision() {
        // Vertical collider (0,0,1 up to 0,0,10) with volume 10
        Collider3D vertical = new Collider3D(new Vector3(0, 0, 1), new Vector3(0, 0, 10));

        // An object in the middle of the vertical collider (z=5)
        Vector3 midPos = new Vector3(0, 0, 5);
        Collider3D midCube = new Collider3D(midPos, midPos);

        assertTrue(vertical.collidesWith(midCube), "The object must collide with the center of the vertical brick");
    }

    @Test
    void testAlmostTouchingButNoCollision() {
        // Cube A at (0,0,0)
        Collider3D a = new Collider3D(new Vector3(0, 0, 0), new Vector3(0, 0, 0));

        // Cube B at (1,0,0)
        Collider3D b = new Collider3D(new Vector3(1, 0, 0), new Vector3(1, 0, 0));

        // Cubes are touching but not colliding (AABB discrete grid logic)
        assertFalse(a.collidesWith(b), "Objects in adjacent cells must not collide");
    }

    @Test
    void testMissOnOneAxisOnly() {
        // Shared X and Y, different Z, must not collide
        Collider3D base = new Collider3D(new Vector3(5, 5, 5), new Vector3(5, 5, 5));
        Collider3D above = new Collider3D(new Vector3(5, 5, 6), new Vector3(5, 5, 6));

        assertFalse(base.collidesWith(above), "They must not collide if there is a gap on the Z axis");
    }

    @Test
    void testTransformUpdatesBoundsX() {
        // Cube at (0,0,0)
        Vector3 start = new Vector3(0, 0, 0);
        Vector3 end = new Vector3(0, 0, 0);
        Collider3D collider = new Collider3D(start, end);

        // Move 5 units in X
        collider.transform(new Vector3(5, 0, 0));

        // Limits are updated
        assertEquals(5, collider.getMinX());
        assertEquals(5, collider.getMaxX());
    }

    @Test
    void testTransformUpdatesBoundsY() {
        // Cube at (0,0,0)
        Vector3 start = new Vector3(0, 0, 0);
        Vector3 end = new Vector3(0, 0, 0);
        Collider3D collider = new Collider3D(start, end);

        // Move 5 units in Y
        collider.transform(new Vector3(0, 5, 0));

        // Limits are updated
        assertEquals(5, collider.getMinY());
        assertEquals(5, collider.getMaxY());
    }

    @Test
    void testTransformUpdatesBoundsZ() {
        // Cube at (0,0,0)
        Vector3 start = new Vector3(0, 0, 0);
        Vector3 end = new Vector3(0, 0, 0);
        Collider3D collider = new Collider3D(start, end);

        // Move 5 units in Z
        collider.transform(new Vector3(0, 0, 5));

        // Limits are updated
        assertEquals(5, collider.getMinZ());
        assertEquals(5, collider.getMaxZ());
    }

    @Test
    void testTransformUpdatesBoundsXYZZ() {
        // Cube at (0,0,0)
        Vector3 start = new Vector3(0, 0, 0);
        Vector3 end = new Vector3(0, 0, 0);
        Collider3D collider = new Collider3D(start, end);

        // Move 2 units in X, 3 in Y and 5 units in Z
        collider.transform(new Vector3(2, 3, 5));

        // Limits are updated
        assertEquals(2, collider.getMinX());
        assertEquals(2, collider.getMaxX());
        assertEquals(3, collider.getMinY());
        assertEquals(3, collider.getMaxY());
        assertEquals(5, collider.getMinZ());
        assertEquals(5, collider.getMaxZ());
    }

    @Test
    void testTransformWithSameInstance() {
        Vector3 sharedPoint = new Vector3(1, 1, 1);

        // Using start and end as the same instance
        Collider3D collider = new Collider3D(sharedPoint, sharedPoint);

        // Move 1 unit in X
        collider.transform(new Vector3(1, 0, 0));

        // Check that only 1 unit of movement is applied once (no double translation)
        assertEquals(2, collider.getMinX(), "Should have moved only once");
    }

    @Test
    void testTransformWithSameInitialPoint() {
        // Created with the same Vector instance for start and end
        Vector3 sharedPoint = new Vector3(1, 1, 1);
        Collider3D collider = new Collider3D(sharedPoint, sharedPoint);

        // Move 1 unit in X
        collider.transform(new Vector3(1, 0, 0));

        // Due to defensive copying in the constructor,
        // it should only move once (result X should be 2, not 3)
        assertEquals(2, collider.getMinX(), "Should have moved exactly 1 unit");
    }

    @Test
    void testNegativeCoordinates() {
        // Move from positive to negative coordinates
        // start(1,1,1) -> end(-1,-1,-1)
        Collider3D brick = new Collider3D(new Vector3(1,1,1), new Vector3(-1,-1,-1));

        // Cube in origin (0,0,0)
        Collider3D center = new Collider3D(new Vector3(0,0,0), new Vector3(0,0,0));

        // Must collide as center is between start and end
        assertTrue(brick.collidesWith(center), "Should detect collision even if start/end points are inverted");
        assertEquals(-1, brick.getMinX());
        assertEquals(1, brick.getMaxX());
    }

    @Test
    void testPointCollisionMethod() {
        // Test the overloaded collidesWith(Vector3)
        Collider3D box = new Collider3D(new Vector3(0, 0, 0), new Vector3(2, 2, 2));

        assertTrue(box.collidesWith(new Vector3(1, 1, 1)), "Point inside should collide");
        assertTrue(box.collidesWith(new Vector3(0, 0, 0)), "Point on min bound should collide");
        assertTrue(box.collidesWith(new Vector3(2, 2, 2)), "Point on max bound should collide");
        assertFalse(box.collidesWith(new Vector3(3, 1, 1)), "Point outside should not collide");
    }
}