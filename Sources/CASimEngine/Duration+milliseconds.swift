extension Duration {
    var inMilliseconds: Double {
        let v = components
        return Double(v.seconds) * 1000 + Double(v.attoseconds) * 1e-15
    }

    var inSeconds: Float {
        let v = components
        return Float(v.seconds) + Float(v.attoseconds) * 1e-18
    }
}
