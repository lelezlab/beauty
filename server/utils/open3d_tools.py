try:
    import open3d as o3d
except Exception:
    o3d = None


def smooth_and_normals(vertices, indices):
    """Return smoothed vertices and normals (placeholder)."""
    if o3d is None:
        return vertices, [[0.0, 0.0, 1.0] for _ in vertices]
    mesh = o3d.geometry.TriangleMesh(
        o3d.utility.Vector3dVector(vertices),
        o3d.utility.Vector3iVector(indices),
    )
    mesh.compute_vertex_normals()
    mesh = mesh.filter_smooth_simple(number_of_iterations=1)
    return (
        mesh.vertices.tolist(),
        mesh.vertex_normals.tolist(),
    )



