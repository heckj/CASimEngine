#if swift(>=6.0)
    internal import CASimEngine
    internal import Voxels
    internal import Testing

    struct CAIndexTests {
        static let testBounds = VoxelBounds(min: [0, 0, 0], max: [9, 9, 9])

        @Test func CAIndexCoreLocations() async throws {
            let linearIndex = try Self.testBounds.linearize([4, 4, 4])
            let idx = CAIndex(linearIndex: linearIndex, bounds: Self.testBounds)

            #expect(idx.bounds == Self.testBounds)
            #expect(try CAIndexTests.testBounds.linearize([4, 4, 4]) == idx.index)
            // manhattan distance 1 neighbors
            #expect(try CAIndexTests.testBounds.linearize([5, 4, 4]) == idx.xr)
            #expect(try CAIndexTests.testBounds.linearize([3, 4, 4]) == idx.xl)
            #expect(try CAIndexTests.testBounds.linearize([4, 5, 4]) == idx.yr)
            #expect(try CAIndexTests.testBounds.linearize([4, 3, 4]) == idx.yl)
            #expect(try CAIndexTests.testBounds.linearize([4, 4, 5]) == idx.zr)
            #expect(try CAIndexTests.testBounds.linearize([4, 4, 3]) == idx.zl)

            #expect(idx.neighborsInBounds.count == 6)

            // manhattan distance 2 neighbors
            #expect(try CAIndexTests.testBounds.linearize([6, 4, 4]) == idx.xr2)
            #expect(try CAIndexTests.testBounds.linearize([2, 4, 4]) == idx.xl2)
            #expect(try CAIndexTests.testBounds.linearize([4, 6, 4]) == idx.yr2)
            #expect(try CAIndexTests.testBounds.linearize([4, 2, 4]) == idx.yl2)
            #expect(try CAIndexTests.testBounds.linearize([4, 4, 6]) == idx.zr2)
            #expect(try CAIndexTests.testBounds.linearize([4, 4, 2]) == idx.zl2)

            #expect(try CAIndexTests.testBounds.linearize([3, 3, 4]) == idx.xl_yl)
            #expect(try CAIndexTests.testBounds.linearize([3, 5, 4]) == idx.xl_yr)
            #expect(try CAIndexTests.testBounds.linearize([5, 3, 4]) == idx.xr_yl)
            #expect(try CAIndexTests.testBounds.linearize([5, 5, 4]) == idx.xr_yr)

            #expect(try CAIndexTests.testBounds.linearize([3, 4, 3]) == idx.xl_zl)
            #expect(try CAIndexTests.testBounds.linearize([3, 4, 5]) == idx.xl_zr)
            #expect(try CAIndexTests.testBounds.linearize([5, 4, 3]) == idx.xr_zl)
            #expect(try CAIndexTests.testBounds.linearize([5, 4, 5]) == idx.xr_zr)

            #expect(try CAIndexTests.testBounds.linearize([4, 3, 3]) == idx.yl_zl)
            #expect(try CAIndexTests.testBounds.linearize([4, 3, 5]) == idx.yl_zr)
            #expect(try CAIndexTests.testBounds.linearize([4, 5, 3]) == idx.yr_zl)
            #expect(try CAIndexTests.testBounds.linearize([4, 5, 5]) == idx.yr_zr)
        }
    }
#endif
