extension Comparable {
    func clamped(within limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }

    func clamped(above value: Self) -> Self {
        min(value, self)
    }

    func clamped(below value: Self) -> Self {
        max(value, self)
    }
}
