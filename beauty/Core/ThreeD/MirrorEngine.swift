import Foundation

/// Thin wrapper over TPSMorph to expose product-level operations with safe bounds.
enum MirrorEngine {
    static func applyNoseTipRotation(_ deg: Double, on mesh: FaceMesh3D) -> FaceMesh3D {
        let p = TPSMorph.Params(tip_rotation: deg,
                                 bridge_straighten: 0,
                                 alar_narrowing: 0,
                                 chin_forward: 0,
                                 gonial_angle_soften: 0)
        return TPSMorph.apply(to: mesh, params: p)
    }

    static func applyChinForward(_ mm: Double, on mesh: FaceMesh3D) -> FaceMesh3D {
        let p = TPSMorph.Params(tip_rotation: 0,
                                 bridge_straighten: 0,
                                 alar_narrowing: 0,
                                 chin_forward: mm,
                                 gonial_angle_soften: 0)
        return TPSMorph.apply(to: mesh, params: p)
    }

    static func applyMandibleSharpness(_ level: Double, on mesh: FaceMesh3D) -> FaceMesh3D {
        let p = TPSMorph.Params(tip_rotation: 0,
                                 bridge_straighten: 0,
                                 alar_narrowing: 0,
                                 chin_forward: 0,
                                 gonial_angle_soften: level)
        return TPSMorph.apply(to: mesh, params: p)
    }
}


