package com.adventofcode.flashk.suites;

import org.junit.platform.suite.api.IncludeTags;
import org.junit.platform.suite.api.SelectPackages;
import org.junit.platform.suite.api.Suite;
import org.junit.platform.suite.api.SuiteDisplayName;

import com.adventofcode.flashk.common.test.constants.TestTag;

@Suite
@IncludeTags(TestTag.PART_TWO)
@SelectPackages({"com.adventofcode.flashk"})
@SuiteDisplayName("Test part 2 from all puzzles")
public class SuiteTestPart2 {

}
