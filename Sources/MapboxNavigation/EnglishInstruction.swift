//
//  EnglishInstruction.swift
//  MapboxNavigation
//
//  Created by Tuan, Pham Hai on 25/05/2023.
//  Copyright © 2023 Mapbox. All rights reserved.
//

import Foundation
import MapboxCoreNavigation
import MapboxDirections

func fixInstruction(_ instruction: VisualInstructionBanner) -> VisualInstructionBanner {

    let primary = fixVisualInstruction(instruction.primaryInstruction)!
    let secondary = fixVisualInstruction(instruction.secondaryInstruction)
    let tertiary = fixVisualInstruction(instruction.tertiaryInstruction)
    let quaternary = fixVisualInstruction(instruction.quaternaryInstruction)
    
    let resultInstructionBanner = VisualInstructionBanner(distanceAlongStep: instruction.distanceAlongStep, primary: primary, secondary: secondary, tertiary: tertiary, quaternary: quaternary, drivingSide: instruction.drivingSide)
    return resultInstructionBanner
}

func fixVisualInstruction(_ original: VisualInstruction?) -> VisualInstruction? {
    
    if let instruction = original {
        //  filter all latin components
        let latinComponents = instruction.components.filter { component in
            switch component {
            case .text(text: let value):
                if value.text == "/" {
                    return false
                }
                if !value.text.isEmpty {
                    let hasSpecialCharacter = value.text.containsChineseOrTamil()
                    return !hasSpecialCharacter
                } else {
                    return true
                }
            default:
                return true
            }
        }
        var text = original?.text
        if let firstComponent = latinComponents.first {
            switch firstComponent {
            case .text(text: let value):
                text = value.text
            default:
                break
            }
        }
        
        let result = VisualInstruction(text: text, maneuverType: instruction.maneuverType, maneuverDirection: instruction.maneuverDirection, components: latinComponents)
        return result
    }
    return nil
}
