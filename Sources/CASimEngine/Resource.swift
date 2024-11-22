public enum PhaseState: UInt8 {
    case solid
    case liquid
    case gas
}

extension PhaseState: Sendable, Hashable, Codable {}

public struct Resource: Sendable, Hashable, Identifiable, Codable, CaseIterable {
    public let name: String
    public let id: UInt8
    
    public let meltingPoint: Float // °c
    public let boilingPoint: Float // °c
    public let porosity: Float // Unit value - 0...1 (%)
                        // let adhesionBreakpoint: UInt8
    
    public let solidDensity: Float // (g/cc)
                            // let solidFlowRate: Float
    
    public let liquidDensity: Float // (g/cc)
                             // let liquidFlowRate: Float
    
    public let gasDensity: Float // (g/cc)
                          // let gasFlowRate: Float
    
    public init(id: UInt8, name: String, meltingPoint: Float, boilingPoint: Float, solidDensity: Float, liquidDensity: Float, gasDensity: Float, solidPorosity: Float) {
        self.id = id
        self.name = name
        
        self.meltingPoint = meltingPoint
        self.boilingPoint = boilingPoint
        
        self.solidDensity = solidDensity
        self.liquidDensity = liquidDensity
        self.gasDensity = gasDensity
        
        self.porosity = solidPorosity
        // self.heatDiffusivity = heatDiffusivity
    }
    
    @inlinable
    public func state(_ temp: Float) -> PhaseState {
        if temp < meltingPoint {
            .solid
        } else if temp > boilingPoint {
            .gas
        } else {
            .liquid
        }
    }
    
    @inlinable
    public func densityAtTemp(_ temp: Float) -> Float {
        if temp < meltingPoint {
            solidDensity
        } else if temp > boilingPoint {
            gasDensity
        } else {
            liquidDensity
        }
    }
    
    /// mass of the resource
    /// - Parameters:
    ///   - unitVolume: unit float value of a 1m3 volume
    ///   - temp: °C
    /// - Returns: kilograms
    @inlinable
    public func mass(_ unitVolume: Float, temp: Float) -> Float {
        // unit volume is 0...1.0 - representing portion of 1m^3
        assert(unitVolume >= 0.0 && unitVolume <= 1.0)
        let density = densityAtTemp(temp)
        return density * 1000.0 * unitVolume
    }
}

