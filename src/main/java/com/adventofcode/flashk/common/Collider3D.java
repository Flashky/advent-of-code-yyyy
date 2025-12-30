package com.adventofcode.flashk.common;

import module java.base;
import lombok.EqualsAndHashCode;
import lombok.Getter;

@Getter
@EqualsAndHashCode
public class Collider3D {

    private final Vector3 start;
    private final Vector3 end;

    private long minX;
    private long maxX;
    private long minY;
    private long maxY;
    private long minZ;
    private long maxZ;

    public Collider3D(Vector3 start, Vector3 end) {
        this.start = new Vector3(start);
        this.end = new Vector3(end);
        calculateMinAndMax();
    }

    public Collider3D(Vector3 pointCollider) {
        this.start = new Vector3(pointCollider);
        this.end = new Vector3(pointCollider);
        calculateMinAndMax();
    }

    public Collider3D(Collider3D other) {
        this.start = new Vector3(other.start);
        this.end = new Vector3(other.end);
        this.minX = other.minX;
        this.maxX = other.maxX;
        this.minY = other.minY;
        this.maxY = other.maxY;
        this.minZ = other.minZ;
        this.maxZ = other.maxZ;
    }

    public void transform(Vector3 vector) {

        start.transform(vector);
        end.transform(vector);

        minX += vector.getX();
        maxX += vector.getX();
        minY += vector.getY();
        maxY += vector.getY();
        minZ += vector.getZ();
        maxZ += vector.getZ();
    }

    private void calculateMinAndMax() {
        // X coordinate values
        this.minX = Math.min(start.getX(), end.getX());
        this.maxX = Math.max(start.getX(), end.getX());

        // Y coordinate values
        this.minY = Math.min(start.getY(), end.getY());
        this.maxY = Math.max(start.getY(), end.getY());

        // Z coordinate values
        this.minZ = Math.min(start.getZ(), end.getZ());
        this.maxZ = Math.max(start.getZ(), end.getZ());
    }

    /// Checks if a point is within the bounds of this collider.
    /// @param point a Vector3 indicating some coordinates.
    /// @return `true` if the point is inside or collides the collider. `false` otherwise.
    public boolean collidesWith(Vector3 point) {
        return point.getX() >= minX && point.getX() <= maxX &&
                point.getY() >= minY && point.getY() <= maxY &&
                point.getZ() >= minZ && point.getZ() <= maxZ;
    }

    /// Checks collision with another Collider3D using AABB (Axis-Aligned Bounding Boxes).
    /// @param other another Collider3D instance
    /// @return `true` if there is a collision between both colliders. `false` otherwise.
    public boolean collidesWith(Collider3D other) {

        return this.minX <= other.maxX &&
                this.maxX >= other.minX &&
                this.minY <= other.maxY &&
                this.maxY >= other.minY &&
                this.minZ <= other.maxZ &&
                this.maxZ >= other.minZ;

    }

}
