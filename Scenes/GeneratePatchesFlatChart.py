import bpy
bpy.ops.mesh.primitive_cube_add()

planeSpacing = 24
numX = 6
numZ = 4
centerX = (numX-1)/2*planeSpacing
centerZ = (numZ-1)/2*planeSpacing
depth= 1000
for c in range(0,numX):
    for r in range(0,numZ):
        x = c*planeSpacing - centerX
        y = depth
        z = r*planeSpacing - centerZ
        bpy.ops.mesh.primitive_cube_add(location=(x,y,z))
        ob = bpy.context.object
        ob.scale = ((12,12,12))
        ob.name = "Patch%d%d" % (r+2,c) 
        mat = bpy.data.materials.new(name= "Patch%d%dMaterial" % (r+2,c))
        ob.data.materials.append(mat)