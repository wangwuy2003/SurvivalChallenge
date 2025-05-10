//
//  FilterTypeManager.swift
//  SurvivalChallenge
//
//  Created by Apple on 9/5/25.
//

import UIKit

// MARK: - Coloring Rule
enum ColoringRule {
    case singlePart(Int)        // Color a single part
    case multipleParts([Int])   // Color multiple parts
    case allParts               // Color all parts
}

// MARK: - Filter Type Configuration
struct FilterTypeConfig {
    let targetImage: UIImage
    let paintImage: UIImage
    let partImages: [String]
    let buttonColors: [UIColor]
    let coloringRules: [Int: ColoringRule]
}

// MARK: - Filter Type Manager
class FilterTypeManager {
    static let shared = FilterTypeManager()
    
    private var filterConfigs: [DesignType: FilterTypeConfig] = [:]
    private var buttonPositions: [DesignType: [UIButton: CGPoint]] = [:]
    
    private init() {
        setupDefaultConfigs()
    }
    
    private func setupDefaultConfigs() {
        // Create each config in separate functions
        filterConfigs = [
            .coloringType1: createType1Config(),
            .coloringType2: createType2Config(),
            .coloringType3: createType3Config(),
            .coloringType4: createType4Config(),
            .coloringType5: createType5Config()
        ]
    }

    private func createType1Config() -> FilterTypeConfig {
        return FilterTypeConfig(
            targetImage: .coloring1,
            paintImage: .paint1,
            partImages: ["thanos_1", "thanos_2", "thanos_3", "thanos_4"],
            buttonColors: [
                .hex237874, // left
                .hex995AC9, // right
                .hexEFBEAA, // top
                .hexCF9781  // bottom
            ],
            coloringRules: [
                0: .singlePart(0),              // left button colors part 0
                1: .singlePart(1),              // right button colors part 1
                2: .multipleParts([0, 1, 2]),   // bottom button colors part 2
                3: .multipleParts([3])          // top button colors all parts
            ]
        )
    }

    private func createType2Config() -> FilterTypeConfig {
        // Break down button colors into a separate variable
        let buttonColors: [UIColor] = [
            .hex272727,         // Black right
            .hexFFD0A4,         // Bottom
            .hex9F64FF,         // Purple left
            .hex313131,         // Black bottom
            .hexFFD83C,         // Yellow left
            .hexFF7637          // Orange right
        ]
        
        // Break down coloring rules into a separate variable
        let coloringRules: [Int: ColoringRule] = [
            0: .singlePart(3),                   // Black right button -> doll_4
            1: .multipleParts([0, 1, 2, 3]),     // Bottom button -> doll_1, doll_2, doll_3
            2: .multipleParts([4, 5]),           // Purple left button -> doll_5, doll_6
            3: .singlePart(5),                   // Black bottom button -> doll_6
            4: .singlePart(0),                   // Yellow left button -> doll_1
            5: .singlePart(1)                    // Orange right button -> doll_2
        ]
        
        return FilterTypeConfig(
            targetImage: .coloring2,
            paintImage: .paint2,
            partImages: ["doll_1", "doll_2", "doll_3", "doll_4", "doll_5", "doll_6"],
            buttonColors: buttonColors,
            coloringRules: coloringRules
        )
    }
    
    private func createType3Config() -> FilterTypeConfig {
        return FilterTypeConfig(
            targetImage: .coloring3,
            paintImage: .paint3,
            partImages: ["456_2", "456_1", "456_4", "456_3"],
            buttonColors: [
                .hex237874, // left
                .hex2E2E2E, // right
                .hexEFBEAA, // top
                .hexCF9781  // bottom
            ],
            coloringRules: [
                0: .singlePart(0),    // left button colors part 0
                1: .singlePart(1),    // right button colors part 1
                2: .multipleParts([0, 1, 2]),    // bottom button colors part 2
                3: .multipleParts([3])   // top button colors part 3
            ]
        )
    }

    private func createType4Config() -> FilterTypeConfig {
        return FilterTypeConfig(
            targetImage: .coloring4,
            paintImage: .paint4,
            partImages: ["goon_1", "goon_2", "goon_3", "goon_4", "goon_5", "goon_6"],
            buttonColors: [
                .hex2AFF7A,  // Green
                .hexFFD230,  // Yellow
                .hex1E9EFF,  // Blue
                .hexFF3030   // red
            ],
            coloringRules: [
                0: .multipleParts([0, 1, 2]),  // Green button -> goon_1, goon_2, goon_3
                1: .multipleParts([3, 4, 5]),  // Yellow button -> goon_4, goon_5, goon_6
                2: .multipleParts([4, 1]),     // Blue button -> goon_5, goon_2
                3: .multipleParts([5, 2])      // Red button -> goon_6, goon_3
            ]
        )
    }

    private func createType5Config() -> FilterTypeConfig {
        return FilterTypeConfig(
            targetImage: .coloring5,
            paintImage: .paint5,
            partImages: ["section_1", "section_2", "section_3", "section_4"],
            buttonColors: [
                .hexFF7637, // orange
                .hex237874, // green
                .hex9537FF  // purple
            ],
            coloringRules: [
                0: .multipleParts([0, 1]),  // Orange button -> section_1, section_2
                1: .multipleParts([1, 2]),  // Green button -> section_4, section_1
                2: .multipleParts([3, 0])   // Purple button -> section_2, section_3
            ]
        )
    }
    
    // MARK: - Public Methods
    
    func getConfig(for designType: DesignType) -> FilterTypeConfig? {
        return filterConfigs[designType]
    }
    
    func saveButtonPositions(for designType: DesignType, positions: [UIButton: CGPoint]) {
        buttonPositions[designType] = positions
    }
    
    func getButtonPositions(for designType: DesignType) -> [UIButton: CGPoint]? {
        return buttonPositions[designType]
    }
    
    func resetButtonPositions(for designType: DesignType) {
        buttonPositions.removeValue(forKey: designType)
    }
}
