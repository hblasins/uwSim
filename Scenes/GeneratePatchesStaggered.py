import bpy
bpy.ops.mesh.primitive_cube_add()

cubeLength = 12
planeSpacing = 24
numX = 6
numZ = 4
centerX = (numX-1)/2*planeSpacing
centerZ = (numZ-1)/2*planeSpacing
cameraRange = 1000
spacing = 100

y = cameraRange
for c in range(0,numX):
    y = y + spacing
    cscale = float(y)/float(cameraRange)
    
    for r in range(0,numZ):
        x = c*planeSpacing - centerX
        z = r*planeSpacing - centerZ
        bpy.ops.mesh.primitive_cube_add(location=(x*cscale,y,z*cscale))
        ob = bpy.context.object
        ob.scale = ((cscale*cubeLength,cscale*cubeLength,cscale*cubeLength))
        ob.name = "Patch%d%d" % (r,c) 
        mat = bpy.data.materials.new(name= "Patch%d%dMaterial" % (r,c))
        ob.data.materials.append(mat)