// GOALS:

// 1) Basic fluid simulation - water flowing over landscapes
// 2) soft/loose solids flowing - angle of repose, and adhesion characteristics
// 3) temperature diffusion - both air, solids, and liquids
// 4) simplified state change for resources - solid <-> liquid <-> gas
// 5) aquifer - fluid flow through porous solids

public struct MultiResourceCell: Sendable, Hashable {
    public var temp: Float // °C

    public var primaryType: UInt8 // Resource.id
    public var primaryTypeVolume: Float = 0 // UnitVolume - 0...1
    public var liquidType: UInt8 // Resource.id
    public var liquidVolume: Float = 0 // UnitVolume - 0...1

    // for free flowing liquids
    public var pressure: Float = 0
    public var flowX: Float = 0 // momentum of movement in +X direction (kg * m / sec)
    public var flowY: Float = 0 // momentum of movement in +Y direction (kg * m / sec)
    public var flowZ: Float = 0 // momentum of movement in +Z direction (kg * m / sec)

    // for aquifer/porous flow
    public var porousPressure: Float = 0
    public var porousFlowX: Float = 0
    public var porousFlowY: Float = 0
    public var porousFlowZ: Float = 0
    
    public init(resource: UInt8, unitFill: Float = 1.0, temp: Float = 20) {
        primaryType = resource
        primaryTypeVolume = unitFill
        self.temp = temp // °C
        liquidType = Resource.water.id
    }

    public static let air = MultiResourceCell(resource: Resource.air.id)
    public static let basalt = MultiResourceCell(resource: Resource.basalt.id)
}

extension MultiResourceCell {
    func isStatic() -> Bool {
        
        // if the static volume is > 90% of the voxel, consider it static
        staticVolume() > 0.9
    }

    @inlinable
    func staticVolume() -> Float {
        var staticVolume: Float = 0
        if Resource.byId(primaryType).state(temp) == .solid {
            staticVolume += primaryTypeVolume
        }
        if Resource.byId(liquidType).state(temp) == .solid {
            staticVolume += liquidVolume
        }
        return staticVolume
    }

    @inlinable
    func fluidVolume() -> Float {
        var staticVolume: Float = 0
        if Resource.byId(primaryType).state(temp) == .liquid {
            staticVolume += primaryTypeVolume
        }
        if Resource.byId(liquidType).state(temp) == .liquid {
            staticVolume += liquidVolume
        }
        return staticVolume
    }

    @inlinable
    func fluidMass() -> Float {
        var v: Float = 0.0
        let primary = Resource.byId(primaryType)
        let liquid = Resource.byId(liquidType)
        if primary.state(temp) == .liquid {
            v += primary.mass(primaryTypeVolume, temp: temp)
        }
        if liquid.state(temp) == .liquid {
            v += liquid.mass(liquidVolume, temp: temp)
        }
        return v
    }
}
