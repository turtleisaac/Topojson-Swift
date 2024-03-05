import Foundation

public enum TopojsonObjectType {
    case Point,
    MultiPoint,
    LineString,
    MutliLineString,
    Polygon,
    MultiPolygon,
    GeometryCollection
    
    static func fromString(type : String) -> TopojsonObjectType? {
        switch(type.lowercased()) {
        case "point": return .Point
        case "multipoint": return .MultiPoint
        case "linestring": return .LineString
        case "multilinestring": return .MutliLineString
        case "polygon": return .Polygon
        case "multipolygon": return .MultiPolygon
        case "geometrycollection": return .GeometryCollection
        default: return nil
        }
    }
}

public protocol TopojsonObject {
    var properties : [String: String] { get }
    var type : TopojsonObjectType { get }
}

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

public struct Topojson {
    public let scale : (Double, Double)?
    public let translate : (Double, Double)?
    public let arcs : [[(Int, Int)]]
    public let type : String
    public let objects : [String : TopojsonObject]
    
    enum Error: Swift.Error, Equatable {
        case invalidFile
    }
    
    private static func extractTransform(transform : [String: Any]) -> (scale: (Double, Double), translate: (Double, Double)) {
        let scale = transform["scale"] as! [Double]
        let translate = transform["translate"] as! [Double]
        

        return (scale: (scale[0], scale[1]), translate: (translate[0], translate[1]))
    }
    
    private static func extractArcs(arcs: [[[Int]]]) -> [[(Int, Int)]] {
        var deltaArcs : [[(Int, Int)]] = []
        arcs.forEach { arc in
            // Within Arc
            var delta = (0, 0)
            var deltaArc : [(Int, Int)] = []
            
            arc.enumerated().forEach { pair in
                let x = pair.element[0] + delta.0
                let y = pair.element[1] + delta.1
                
                delta = (x, y)
                deltaArc.append(delta)
            }
            
            deltaArcs.append(deltaArc)
        }
        
        return deltaArcs
    }
    
    private static func extractObject(object: [String: Any]) throws -> TopojsonObject {
        guard let typeString = object["type"] as? String else {
            throw Error.invalidFile
        }
        
        
        guard let type = TopojsonObjectType.fromString(type: typeString) else {
            throw Error.invalidFile
        }
        
        let properties = object["properties"] as? NSDictionary ?? [:]
        
        var newProperties = [String : String]()
        
        for key in properties.allKeys {
            newProperties["\(key)"] = "\(properties[key]!)"
        }

        
        switch(type) {
        case .Point:
            guard let coords = object["coordinates"] as? [Double] else {
                throw Error.invalidFile
            }

            return TopojsonPointObject(
                properties: newProperties,
                type: type,
                coordinates: (coords[0], coords[1])
            )
            
        case .MultiPoint:
            guard let coords = object["coordinates"] as? [[Double]] else {
                throw Error.invalidFile
            }

            let tuples = coords.map{ coord in (coord[0], coord[1]) }
            
            return TopojsonMultiPointObject(
                properties: newProperties,
                type: type,
                coordinates: tuples
            )
            
        case .LineString:
            guard let arcs = object["arcs"] as? [Int] else {
                throw Error.invalidFile
            }

            return TopojsonLineStringObject(
                properties: newProperties,
                type: type,
                arcs: arcs
            )
            
        case .MutliLineString:
            guard let arcs = object["arcs"] as? [[Int]] else {
                throw Error.invalidFile
            }

            return TopojsonMultiLineStringObject(
                properties: newProperties,
                type: type,
                arcs: arcs
            )
        case .Polygon:
            guard let arcs = object["arcs"] as? [[Int]] else {
                throw Error.invalidFile
            }

            return TopojsonPolygonObject(
                properties: newProperties,
                type: type,
                arcs: arcs
            )
            
        case .MultiPolygon:
            guard let arcs = object["arcs"] as? [[[Int]]] else {
                throw Error.invalidFile
            }
            
            return TopojsoMultiPolygonObject(
                properties: newProperties,
                type: type,
                arcs: arcs)
            
        case .GeometryCollection:
            guard let geometries = object["geometries"] as? [[String: Any]] else {
                throw Error.invalidFile
            }
            
            return TopojsonGeometryCollectionObject(
                properties: newProperties,
                type: type,
                geometries: try geometries.map { object in try Topojson.extractObject(object: object) }
            )
        }

    }
    
    public init(_ file: URL) throws {
        let data = try Data(contentsOf: file)
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        if let root = json as? [String: Any] {
                        
            // Extract Transform
            if let transform = root["transform"] as? [String: Any] {
                let transform = Topojson.extractTransform(transform: transform)
                self.scale = transform.scale
                self.translate = transform.translate
            } else {
                self.scale = nil
                self.translate = nil
            }

            // Extract Arcs
            if let arcs = root["arcs"] as? [[[Int]]] {
                self.arcs = Topojson.extractArcs(arcs: arcs)
            } else {
                throw Error.invalidFile
            }
            
            // Extract Type
            if let type = root["type"] as? String {
                self.type = type
            } else {
                throw Error.invalidFile
            }

            var objects :  [String : TopojsonObject] = [:]

            // Extract Objects
            if let allObjects = root["objects"] as? [String: [String: Any]] {
                try allObjects.forEach {
                    objects.updateValue(try Topojson.extractObject(object: $0.value), forKey: $0.key)
                }
            } else {
                throw Error.invalidFile
            }
            self.objects = objects

        } else {
            throw Error.invalidFile
        }
    }
    
    public func transformedArc(arc: Int) -> [(Double, Double)] {
        var coords = self.arcs[abs(arc)]
        
        if arc < 0 {
            coords.reverse()
        }
        
        return coords.map{
            var coords = (Double($0.0), Double($0.1))
            
            if let scale = self.scale {
                coords.0 *= scale.0
                coords.1 *= scale.1
            }
            
            
            if let translate = self.translate {
                coords.0 += translate.0
                coords.1 += translate.1
            }
            
            return coords
        }
    }
        
}
