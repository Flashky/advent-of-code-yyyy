package com.adventofcode.flashk.common;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class Collider2DTest {

    @Test
    void testIdenticalObjectsCollide() {
        // Two 1x1 squares at the same position must collide
        Vector2 pos = new Vector2(2, 2);
        Collider2D a = new Collider2D(pos, pos);
        Collider2D b = new Collider2D(pos, pos);

        assertTrue(a.collidesWith(b), "Identical objects must collide");
    }

    @Test
    void testRectHorizontalOverlap() {
        // Horizontal collider (0,10 to 1,10)
        Collider2D horizontal = new Collider2D(new Vector2(0, 10), new Vector2(1, 10));

        // A single square occupies one of the collider cells (1,10)
        Vector2 squarePos = new Vector2(1, 10);
        Collider2D square = new Collider2D(squarePos, squarePos);

        assertTrue(horizontal.collidesWith(square), "The square must collide with the edge of the horizontal collider");
    }

    @Test
    void testRectVerticalCollision() {
        // Vertical collider (0,1 to 0,10)
        Collider2D vertical = new Collider2D(new Vector2(0, 1), new Vector2(0, 10));

        // An object in the middle of the vertical collider (y=5)
        Vector2 midPos = new Vector2(0, 5);
        Collider2D midSquare = new Collider2D(midPos, midPos);

        assertTrue(vertical.collidesWith(midSquare), "The object must collide with the center of the vertical collider");
    }

    @Test
    void testAlmostTouchingButNoCollision() {
        // Square A at (0,0)
        Collider2D a = new Collider2D(new Vector2(0, 0), new Vector2(0, 0));

        // Square B at (1,0)
        Collider2D b = new Collider2D(new Vector2(1, 0), new Vector2(1, 0));

        // Objects are adjacent but do not overlap, so they shouldn't collide
        assertFalse(a.collidesWith(b), "Objects in adjacent cells must not collide");
    }

    @Test
    void testMissOnOneAxisOnly() {
        // Shared X but different Y, must not collide
        Collider2D base = new Collider2D(new Vector2(5, 5), new Vector2(5, 5));
        Collider2D above = new Collider2D(new Vector2(5, 6), new Vector2(5, 6));

        assertFalse(base.collidesWith(above), "They should not collide if there is a gap on the Y axis");
    }

    @Test
    void testTransformUpdatesBoundsX() {
        // Square at (0,0)
        Vector2 start = new Vector2(0, 0);
        Vector2 end = new Vector2(0, 0);
        Collider2D collider = new Collider2D(start, end);

        // Move 5 units in X
        collider.transform(new Vector2(5, 0));

        // Limits are updated
        assertEquals(5, collider.getMinX());
        assertEquals(5, collider.getMaxX());
    }

    @Test
    void testTransformUpdatesBoundsY() {
        // Square at (0,0)
        Vector2 start = new Vector2(0, 0);
        Vector2 end = new Vector2(0, 0);
        Collider2D collider = new Collider2D(start, end);

        // Move 5 units in Y
        collider.transform(new Vector2(0, 5));

        // Limits are updated
        assertEquals(5, collider.getMinY());
        assertEquals(5, collider.getMaxY());
    }

    @Test
    void testTransformUpdatesBoundsXY() {
        // Square at (0,0)
        Vector2 start = new Vector2(0, 0);
        Vector2 end = new Vector2(0, 0);
        Collider2D collider = new Collider2D(start, end);

        // Move 2 units in X and 3 units in Y
        collider.transform(new Vector2(2, 3));

        // Check all bounds
        assertEquals(2, collider.getMinX());
        assertEquals(3, collider.getMinY());
        assertEquals(2, collider.getMaxX());
        assertEquals(3, collider.getMaxY());
    }

    @Test
    void testTransformWithSameInstance() {
        Vector2 sharedPoint = new Vector2(1, 1);
        Collider2D collider = new Collider2D(sharedPoint, sharedPoint);

        // Move 1 unit in X
        collider.transform(new Vector2(1, 0));

        // Verify that movement was only applied once (avoiding double movement if shared instances are used)
        assertEquals(2, collider.getMinX(), "Should have moved only once");
    }

    @Test
    void testNegativeCoordinates() {
        // Inverted collider: start(1,1) -> end(-1,-1)
        Collider2D rect = new Collider2D(new Vector2(1, 1), new Vector2(-1, -1));

        // Point at the origin (0,0)
        Collider2D center = new Collider2D(new Vector2(0, 0), new Vector2(0, 0));

        // Must collide as origin is within the range [-1, 1]
        assertTrue(rect.collidesWith(center), "Should detect collision even if start/end points are inverted");
        assertEquals(-1, rect.getMinX());
        assertEquals(1, rect.getMaxX());
    }
}