import bpy
bpy.ops.mesh.primitive_cube_add()

planeSpacing = 25
depthSpacing = 100
for c in range(0,4):
    for r in range(-3,3):
        x = c*planeSpacing
        y = 1000 + c*depthSpacing
        z = r*planeSpacing
        bpy.ops.mesh.primitive_cube_add(location=(x,y,z))
        ob = bpy.context.object
        ob.scale = ((12,12,12))
        ob.name = "Patch%d%d" % (r+3,c) 
        mat = bpy.data.materials.new(name= "Patch%d%dMaterial" % (r+3,c))
        ob.data.materials.append(mat)