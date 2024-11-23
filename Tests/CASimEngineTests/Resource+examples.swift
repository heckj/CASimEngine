public extension Resource {
    static let allCases = [water, seawater, oil,
                           air,
                           topsoil, sand, gravel,
                           basalt, limestone, granite, marble, shale, sandstone]

    static let indexedCases: [UInt8: Resource] = {
        var lookupTable: [UInt8: Resource] = [:]
        for r in allCases {
            lookupTable[r.id] = r
        }
        return lookupTable
    }()

    static func byId(_ id: UInt8) -> Resource {
        indexedCases[id] ?? .air
    }

    static let water = Resource(id: 0, name: "water",
                                meltingPoint: 0, boilingPoint: 100,
                                solidDensity: 0.916, liquidDensity: 1.0, gasDensity: 0.804 / 1000.0,
                                solidPorosity: 0)
    static let seawater = Resource(id: 1, name: "seawater",
                                   meltingPoint: -2.0, boilingPoint: 102,
                                   solidDensity: 0.86, liquidDensity: 1.02, gasDensity: 0.804 / 1000.0,
                                   solidPorosity: 0)
    static let oil = Resource(id: 2, name: "oil",
                              meltingPoint: 12, boilingPoint: 180,
                              solidDensity: 0.916, liquidDensity: 0.91, gasDensity: 0.75 / 1000.0,
                              solidPorosity: 0)

    static let air = Resource(id: 3, name: "air",
                              meltingPoint: -210, boilingPoint: -196,
                              solidDensity: 1.5, liquidDensity: 0.87, gasDensity: 1.225 / 1000.0,
                              solidPorosity: 0)

    static let topsoil = Resource(id: 4, name: "topsoil",
                                  meltingPoint: 800, boilingPoint: 9999,
                                  solidDensity: 1.1, liquidDensity: 2.5, gasDensity: 1.5 / 1000.0,
                                  solidPorosity: 0.2)
    static let loam = Resource(id: 13, name: "loam",
                               meltingPoint: 800, boilingPoint: 9999,
                               solidDensity: 1.3, liquidDensity: 2.5, gasDensity: 1.5 / 1000.0,
                               solidPorosity: 0.3)
    static let sand = Resource(id: 5, name: "sand",
                               meltingPoint: 1300, boilingPoint: 9999,
                               solidDensity: 1.4, liquidDensity: 2.5, gasDensity: 1.5 / 1000.0,
                               solidPorosity: 0.4)
    static let gravel = Resource(id: 6, name: "gravel",
                                 meltingPoint: 1300, boilingPoint: 9999,
                                 solidDensity: 2.4, liquidDensity: 2.5, gasDensity: 1.5 / 1000.0,
                                 solidPorosity: 0.6)

    static let basalt = Resource(id: 7, name: "basalt",
                                 meltingPoint: 1000, boilingPoint: 9999,
                                 solidDensity: 2.9, liquidDensity: 2.5, gasDensity: 1.5 / 1000.0,
                                 solidPorosity: 0)
    static let limestone = Resource(id: 8, name: "limestone",
                                    meltingPoint: 1500, boilingPoint: 9999,
                                    solidDensity: 1.36, liquidDensity: 2.5, gasDensity: 1.5 / 1000.0,
                                    solidPorosity: 0.05)
    static let granite = Resource(id: 9, name: "granite",
                                  meltingPoint: 1230, boilingPoint: 9999,
                                  solidDensity: 2.65, liquidDensity: 2.5, gasDensity: 1.5 / 1000.0,
                                  solidPorosity: 0)
    static let marble = Resource(id: 10, name: "marble",
                                 meltingPoint: 1339, boilingPoint: 9999,
                                 solidDensity: 2.8, liquidDensity: 2.5, gasDensity: 1.5 / 1000.0,
                                 solidPorosity: 0)
    static let shale = Resource(id: 11, name: "shale",
                                meltingPoint: 700, boilingPoint: 9999,
                                solidDensity: 2.0, liquidDensity: 2.5, gasDensity: 1.5 / 1000.0,
                                solidPorosity: 0.15)
    static let sandstone = Resource(id: 12, name: "sandstone",
                                    meltingPoint: 1100, boilingPoint: 9999,
                                    solidDensity: 2.3, liquidDensity: 2.5, gasDensity: 1.5 / 1000.0,
                                    solidPorosity: 0.25)
}
