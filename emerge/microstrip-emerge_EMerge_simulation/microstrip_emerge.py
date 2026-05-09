## EMerge simulation
#
#
# To be run with python.
# FreeCAD to OpenEMS plugin but this time it generates EMerge by Lubomir Jagos, 
# see https://github.com/LubomirJagos42/FreeCAD-OpenEMS-Export
#
# This file has been automatically generated. Manual changes may be overwritten.
#

### Import Libraries
import math
import numpy as np
import emerge as em
import os, tempfile, shutil

# Change current path to script file folder
#
abspath = os.path.abspath(__file__)
dname = os.path.dirname(abspath)
os.chdir(dname)
## constants
unit    = 0.001 # Model coordinates and lengths will be specified in mm.
fc_unit = 0.001 # STL files are exported in FreeCAD standard units (mm).


currDir = os.getcwd()
print(currDir)

## prepare simulation folder, if dir exits remove and create new one to be empty
Sim_Path = os.path.join(currDir, 'simulation_output')
if os.path.exists(Sim_Path):
	shutil.rmtree(Sim_Path)   # clear previous directory
	os.mkdir(Sim_Path)    # create empty simulation folder

# --- Unit definitions -----------------------------------------------------
m = 1.0
cm = 0.01
mm = 0.001  # meters per millimeter
um = 0.000001
nm = 0.000000001

pF = 1e-12  # picofarad in farads
fF = 1e-15  # femtofarad in farads
pH = 1e-12  # picohenry in henrys
nH = 1e-9  # nanohenry in henrys

simulationObj = em.Simulation("microstrip", save_file=True)
simulationObj.mw.solveroutine.set_solver(em.EMSolver.PARDISO)

#######################################################################################################################################
# EXCITATION 3ghz
#######################################################################################################################################
fmin = 2.5*1000000000.0
fmax = 3.5*1000000000.0
resolution = 0.2
npoints = 30
simulationObj.mw.set_frequency_range(fmin, fmax, npoints)
simulationObj.mw.set_resolution(resolution)

#######################################################################################################################################
# MATERIALS AND GEOMETRY
#######################################################################################################################################
materialList = {}

## MATERIAL - PEC
materialList['PEC'] = em.lib.PEC
materialList['PEC'].color = '#ab5400'
materialList['PEC'].opacity = 1.0

stepObjectGroup = em.geo.step.STEPItems(name='copper', filename=os.path.join(currDir,'copper_gen_model.step'), unit=mm)
for geoObj in stepObjectGroup.objects:
	geoObj.prio_set(9800)
	geoObj.set_material(materialList['PEC'])

## MATERIAL - air
materialList['air'] = em.Material(name='air', er=1, ur=1)
materialList['air'].color = '#adb5bd'
materialList['air'].opacity = -99.0

stepObjectGroup = em.geo.step.STEPItems(name='airbox', filename=os.path.join(currDir,'airbox_gen_model.step'), unit=mm)
for geoObj in stepObjectGroup.objects:
	geoObj.prio_set(9600)
	geoObj.set_material(materialList['air'])

## MATERIAL - fr4
materialList['fr4'] = em.Material(name='fr4', er=4.5, ur=1)
materialList['fr4'].color = '#507c69'
materialList['fr4'].opacity = -29.0

stepObjectGroup = em.geo.step.STEPItems(name='prepag', filename=os.path.join(currDir,'prepag_gen_model.step'), unit=mm)
for geoObj in stepObjectGroup.objects:
	geoObj.prio_set(9700)
	geoObj.set_material(materialList['fr4'])


# Imported objects used as boundary conditions
#

stepObjectGroup = em.geo.step.STEPItems(name='airbox', filename=os.path.join(currDir,'airbox_gen_model.step'), unit=mm)
for geoObj in stepObjectGroup.objects:
	geoObj.prio_set(9500)

#######################################################################################################################################
# PORTS
#######################################################################################################################################
port = {}
portNamesAndNumbersList = {}


## PORT - portin - in
portStart = [ 0.6, 24.5, -0.035 ]
portStop  = [ 0.6, 25.5, 1.565 ]
portStart = [k*0.001 for k in portStart]
portStop = [k*0.001 for k in portStop]


port[1] = {}
port[1]['portStart'] = portStart
port[1]['portStop'] = portStop
w = abs(portStart[0] - portStop[0])
h = abs(portStart[1] - portStop[1])
th = abs(portStart[2] - portStop[2])
port[1]['w'] = w
port[1]['h'] = h
port[1]['th'] = th
port[1]['portR'] = 50*1
port[1]['portDirection'] = em.ZAX
port[1]['portExcitationAmplitude'] = 1.0
port[1]['object'] = em.geo.Plate(name='in', origin=portStart, u=[0,h,0], v=[0,0,th])
portNamesAndNumbersList["in"] = 1

## PORT - portout - out
portStart = [ 49.4, 24.5, -0.035 ]
portStop  = [ 49.4, 25.5, 1.565 ]
portStart = [k*0.001 for k in portStart]
portStop = [k*0.001 for k in portStop]


port[2] = {}
port[2]['portStart'] = portStart
port[2]['portStop'] = portStop
w = abs(portStart[0] - portStop[0])
h = abs(portStart[1] - portStop[1])
th = abs(portStart[2] - portStop[2])
port[2]['w'] = w
port[2]['h'] = h
port[2]['th'] = th
port[2]['portR'] = 50*1
port[2]['portDirection'] = em.ZAX
port[2]['portExcitationAmplitude'] = 1.0
port[2]['object'] = em.geo.Plate(name='out', origin=portStart, u=[0,h,0], v=[0,0,th])
portNamesAndNumbersList["out"] = 2

#######################################################################################################################################
# COMPLETE GEOMETRY
#######################################################################################################################################

simulationObj.commit_geometry()

#######################################################################################################################################
# GRID LINES
#######################################################################################################################################

#	max element size for 'airbox'
#
for geometryObj in simulationObj.state.manager.geometry_list[simulationObj.modelname].values():
		if geometryObj.name == 'airbox' or geometryObj.name.startswith('airbox_'):
			simulationObj.mesher.set_size(geometryObj, 30.0 * mm)


#	max element size for 'prepag'
#
for geometryObj in simulationObj.state.manager.geometry_list[simulationObj.modelname].values():
		if geometryObj.name == 'prepag' or geometryObj.name.startswith('prepag_'):
			simulationObj.mesher.set_size(geometryObj, 30.0 * mm)


#	max element size for 'copper'
#
for geometryObj in simulationObj.state.manager.geometry_list[simulationObj.modelname].values():
		if geometryObj.name == 'copper' or geometryObj.name.startswith('copper_'):
			simulationObj.mesher.set_boundary_size(geometryObj, 1.0 * mm)



#
# First mesh must be created on existing geometry
#
simulationObj.generate_mesh()


#
# Now follows boundary condition definition
#
simulationObj.mw.bc.LumpedPort(port[1]['object'], 1, width=port[1]['h'], height=port[1]['th'], direction=port[1]['portDirection'], Z0=port[1]['portR'], power=port[1]['portExcitationAmplitude'])
simulationObj.mw.bc.LumpedPort(port[2]['object'], 2, width=port[2]['h'], height=port[2]['th'], direction=port[2]['portDirection'], Z0=port[2]['portR'])

#######################################################################################################################################
# BOUNDARY CONDITIONS PART
#######################################################################################################################################

# BOUNDARY CONDITION NAME: abc
# TYPE: Absorbing
boundary_selection = None
for geometryObj in simulationObj.state.manager.geometry_list[simulationObj.modelname].values():
	if geometryObj.name == 'airbox' or geometryObj.name.startswith('airbox'):
		boundary_selection = geometryObj.boundary()
simulationObj.mw.bc.AbsorbingBoundary(boundary_selection)


#######################################################################################################################################
# EXPERIMENT EXPORT MESH WITH NAMED GROUP OF MESH
#######################################################################################################################################
import gmsh

def createGmshNamedGroup(geometryObjName: str, groupName: str, groupTag: int = -1, useBoundary: bool = False, useSuffixToRecognizeGeometryName: bool = True):
	objectTag1DList = []
	objectTag2DList = []
	objectTag3DList = []

	for geometryObj in simulationObj.state.manager.geometry_list[simulationObj.modelname].values():
		if geometryObj.name == geometryObjName or geometryObj.name.startswith(geometryObjName + ('_' if useSuffixToRecognizeGeometryName else '')):
			for tagTuple in (geometryObj.boundary().dimtags if useBoundary else geometryObj.dimtags):
				if tagTuple[0] == 1:
					objectTag1DList.append(tagTuple[1])
				if tagTuple[0] == 2:
					objectTag2DList.append(tagTuple[1])
				if tagTuple[0] == 3:
					objectTag3DList.append(tagTuple[1])

	if groupTag > -1:
		gmsh.model.addPhysicalGroup(1, objectTag1DList, name=groupName, tag=groupTag)
		gmsh.model.addPhysicalGroup(2, objectTag2DList, name=groupName, tag=groupTag + 1)
		gmsh.model.addPhysicalGroup(3, objectTag3DList, name=groupName, tag=groupTag + 2)
	else:
		gmsh.model.addPhysicalGroup(1, objectTag1DList, name=groupName)
		gmsh.model.addPhysicalGroup(2, objectTag2DList, name=groupName)
		gmsh.model.addPhysicalGroup(3, objectTag3DList, name=groupName)

createGmshNamedGroup('in', 'in')
createGmshNamedGroup('airbox', 'airbox')
createGmshNamedGroup('copper', 'copper')
createGmshNamedGroup('out', 'out')
createGmshNamedGroup('prepag', 'prepag')
createGmshNamedGroup('airbox', 'airboxBoundary', useBoundary=True)

simulationObj.export('microstrip.msh')

#######################################################################################################################################
# DISPLAY MODEL
#######################################################################################################################################
simulationObj.view()
simulationObj.view(plot_mesh=True, volume_mesh=False)

#######################################################################################################################################
# RUN and save results
#######################################################################################################################################
simulationObj.settings.check_ram = False
simulationResult = simulationObj.mw.run_sweep()
simulationObj.save()

