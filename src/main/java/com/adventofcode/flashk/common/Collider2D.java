package com.adventofcode.flashk.common;

import module java.base;

import lombok.Getter;

@Getter
public class Collider2D {

	private final Vector2 start;
	private final Vector2 end;
	
	private long minX;
	private long maxX;
	private long minY;
	private long maxY;
	
	public Collider2D(Vector2 start, Vector2 end) {
		this.start = new Vector2(start);
		this.end = new Vector2(end);
	
		calculateMinAndMax(start, end);
	}
	
	public Collider2D(Vector2 pointCollider) {
		this.start = new Vector2(pointCollider);
		this.end = new Vector2(pointCollider);
		minX = pointCollider.getX();
		maxX = pointCollider.getX();
		minY = pointCollider.getY();
		maxY = pointCollider.getY();
	}

	public Collider2D(Collider2D other) {
		this.start = new Vector2(other.start);
		this.end = new Vector2(other.end);
		this.minX = other.minX;
		this.maxX = other.maxX;
		this.minY = other.minY;
		this.maxY = other.maxY;
	}
	
	public void transform(Vector2 vector) {

		start.transform(vector);
		end.transform(vector);

		// Update bounds
		minX += vector.getX();
		maxX += vector.getX();
		minY += vector.getY();
		maxY += vector.getY();
	}

	public boolean collidesWith(Vector2 point) {
		return point.getX() >= minX && point.getX() <= maxX &&
				point.getY() >= minY && point.getY() <= maxY;
	}

	public boolean collidesWith(Collider2D other) {
		 return this.minX <= other.maxX && 
				 this.maxX >= other.minX && 
				 this.minY <= other.maxY && 
				 this.maxY >= other.minY;
	}

	private void calculateMinAndMax(Vector2 start, Vector2 end) {
		this.minX = Math.min(start.getX(), end.getX());
		this.maxX = Math.max(start.getX(), end.getX());
		this.minY = Math.min(start.getY(), end.getY());
		this.maxY = Math.max(start.getY(), end.getY());
	}
	
	@Override
	public int hashCode() {
		return Objects.hash(maxX, maxY, minX, minY);
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		Collider2D other = (Collider2D) obj;
		return maxX == other.maxX && maxY == other.maxY && minX == other.minX && minY == other.minY;
	}
}
