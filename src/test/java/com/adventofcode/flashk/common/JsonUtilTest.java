package com.adventofcode.flashk.common;

import com.adventofcode.flashk.common.test.constants.TestFilename;
import com.google.gson.JsonElement;

import org.junit.jupiter.api.Test;
import tools.jackson.databind.JsonNode;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

import static org.junit.jupiter.api.Assertions.*;

class JsonUtilTest {

    private static final String COMMON_RESOURCE_PATH = "src/test/resources/common";

    // Test files
    public static final String ARRAY_JSON = "array.json";
    public static final String INVALID_JSON = "invalid.json";

    @Test
    void buildTreeFromArrayJsonTest() {
        String content = readResource(ARRAY_JSON);
        JsonNode jsonNode = JsonUtil.buildTree(content);

        assertNotNull(jsonNode);
        assertTrue(jsonNode.isArray());

        assertEquals(2,jsonNode.get(0).asInt());
        assertEquals(3,jsonNode.get(1).asInt());
        assertEquals(4,jsonNode.get(2).asInt());
    }

    @Test
    void buildTreeFromInvalidJsonTest() {
        String content = readResource(INVALID_JSON);
        assertThrows(IllegalArgumentException.class, () -> JsonUtil.buildTree(content));
    }

    @Test
    void buildGsonTreeTest() {

        String content = readResource(ARRAY_JSON);
        JsonElement jsonElement = JsonUtil.buildGsonTree(content);

        assertNotNull(jsonElement);
        assertTrue(jsonElement.isJsonArray());

        assertEquals(2, jsonElement.getAsJsonArray().get(0).getAsInt());
        assertEquals(3, jsonElement.getAsJsonArray().get(1).getAsInt());
        assertEquals(4, jsonElement.getAsJsonArray().get(2).getAsInt());
    }

    @Test
    void isIntTest() {

        String content = readResource(ARRAY_JSON);
        JsonElement jsonElement = JsonUtil.buildGsonTree(content).getAsJsonArray().get(0);

        assertTrue(JsonUtil.isInt(jsonElement));
    }

    private String readResource(String filename) {
        try {
            Path path = Paths.get(COMMON_RESOURCE_PATH, filename).toAbsolutePath();
            return Files.readString(path);
        } catch (IOException e) {
            throw new RuntimeException("Failed to read test resource file: " + filename, e);
        }
    }
}