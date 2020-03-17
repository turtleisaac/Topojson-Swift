# Topojson-Swift

![Travis Output](https://travis-ci.com/alisle/Topojson-Swift.svg?branch=master)

Minimal package to load and parse a Topojson file.

To load a file:
```swift
let topo = try Topojson(self.url)
```

Once a file is loaded the structure is as follows:

```swift
public struct Topojson {
    public let scale : (Double, Double)?
    public let translate : (Double, Double)?
    public let arcs : [[(Int, Int)]]
    public let type : String
    public let objects : [String : TopojsonObject]
}
```

The objects which are supported are:

```swift
public enum TopojsonObjectType {
    case Point,
    MultiPoint,
    LineString,
    MutliLineString,
    Polygon,
    MultiPolygon,
    GeometryCollection
}
```

Each object has it's own struct sharing the protocol:

``` swift
public protocol TopojsonObject {
    var properties : [String: String] { get }
    var type : TopojsonObjectType { get }
}
```

The individual types are defined as:
```swift

public struct TopojsonPointObject : TopojsonObject {
    public let properties : [String: String]
    public let type : TopojsonObjectType
    public let coordinates : (Double, Double)
        
}

public struct TopojsonMultiPointObject : TopojsonObject {
    public let properties : [String: String]
    public let type : TopojsonObjectType
    public let coordinates : [(Double, Double)]
}

public struct TopojsonLineStringObject : TopojsonObject {
    public let properties : [String: String]
    public let type : TopojsonObjectType
    public let arcs : [Int]
}

public struct TopojsonMultiLineStringObject : TopojsonObject {
    public let properties : [String: String]
    public let type : TopojsonObjectType
    public let arcs : [[Int]]
}

public struct TopojsonPolygonObject : TopojsonObject {
    public let properties : [String: String]
    public let type : TopojsonObjectType
    public let arcs : [[Int]]
}

public struct TopojsoMultiPolygonObject : TopojsonObject {
    public let properties : [String: String]
    public let type : TopojsonObjectType
    public let arcs : [[[Int]]]
}

public struct TopojsonGeometryCollectionObject : TopojsonObject {
    public let properties : [String: String]
    public let type : TopojsonObjectType
    public let geometries : [TopojsonObject]
}

```

To process a arc from one of the objects defined above to latitute / longitude you can use:

```swift

let topo = try Topojson(self.url)
let updatedArc = topo.transformedArc(arc: 0)
        
```

