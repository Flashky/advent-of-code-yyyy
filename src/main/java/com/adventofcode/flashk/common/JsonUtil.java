package com.adventofcode.flashk.common;

import com.google.gson.Gson;
import com.google.gson.JsonElement;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;

public final class JsonUtil {

	private JsonUtil() {}
	
	/// Builds a json tree.
	///
    /// Input accepts basic json and even simple arrays such as:
    /// ```
    /// [4]
    /// [1,1,3,1,1]
    /// [[[],[],8,3],[10]]
    /// [[2],[3,[[],[1]],[],[0,[10,7]]],[[]],[7,[6],8,[9,0],[2]]]
    /// ```
    /// This is useful for AoC puzzles such as 2021 day 18 and 2022 day 13.
    /// @param input the input string
    /// @return The parsed `JsonNode` Jackson based tree.
	public static JsonNode buildTree(String input) {
		try {
			return JsonMapper.builder().build().readTree(input);

		} catch (JacksonException _) {
			throw new IllegalArgumentException("The file "+input+" has wrong format.");
		}
	}

	/// Builds a json tree using Gson library.
	/// 
    /// Input accepts basic json and even simple arrays such as:
    /// ```
    /// [4]
    /// [1,1,3,1,1]
    /// [[[],[],8,3],[10]]
    /// [[2],[3,[[],[1]],[],[0,[10,7]]],[[]],[7,[6],8,[9,0],[2]]]
    /// ```
    /// This is useful for AoC puzzles such as 2021 day 18 and 2022 day 13.
    /// @param input the input string
    /// @return The parsed `JsonElement` Gson based tree.
	public static JsonElement buildGsonTree(String input) {
		return new Gson().fromJson(input, JsonElement.class);
	}

	/// Checks if a Gson `JsonElement` is an integer.
    /// @param element the element to check
    /// @return true if element is a primitive integer. False otherwise
	public static boolean isInt(JsonElement element) {
		return element.isJsonPrimitive() && element.getAsJsonPrimitive().isNumber();
	}
	
}