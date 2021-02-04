import MapboxMaps

extension Expression {
    
    static func routeLineWidthExpression(_ multiplier: Double = 1.0) -> Expression {
        return Exp(.interpolate) {
            Exp(.linear)
            Exp(.zoom)
            RouteLineWidthByZoomLevel.multiplied(by: multiplier)
        }
    }
    
    static func routeLineGradientExpression(_ gradientStops: [Double: UIColor]) -> Expression {
        return Exp(.interpolate) {
            Exp(.linear)
            Exp(.lineProgress)
            gradientStops
        }
    }
}