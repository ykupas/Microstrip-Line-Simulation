% OpenEMS FDTD Analysis Automation Script
%
% To be run with GNU Octave or MATLAB.
% FreeCAD to OpenEMS plugin by Lubomir Jagos, 
% see https://github.com/LubomirJagos/FreeCAD-OpenEMS-Export
%
% This file has been automatically generated. Manual changes may be overwritten.
%

close all
clear
clc

%% Change the current folder to the folder of this m-file.
if(~isdeployed)
  mfile_name          = mfilename('fullpath');
  [pathstr,name,ext]  = fileparts(mfile_name);
  cd(pathstr);
end

%% constants
physical_constants;
unit    = 0.001; % Model coordinates and lengths will be specified in mm.
fc_unit = 0.001; % STL files are exported in FreeCAD standard units (mm).

%% switches & options
postprocessing_only = 0;
draw_3d_pattern = 0; % this may take a while...
use_pml = 0;         % use pml boundaries instead of mur

currDir = strrep(pwd(), '\', '\\');
display(currDir);

% --no-simulation : dry run to view geometry, validate settings, no FDTD computations
% --debug-PEC     : generated PEC skeleton (use ParaView to inspect)
openEMS_opts = '--debug-PEC';

%% prepare simulation folder
Sim_Path = 'simulation_output';
Sim_CSX = 'microstrip.xml';
[status, message, messageid] = rmdir( Sim_Path, 's' ); % clear previous directory
[status, message, messageid] = mkdir( Sim_Path ); % create empty simulation folder

%% setup FDTD parameter & excitation function
max_timesteps = 100000;
min_decrement = 1e-08; % 10*log10(min_decrement) dB  (i.e. 1E-5 means -50 dB)
FDTD = InitFDTD( 'NrTS', max_timesteps, 'EndCriteria', min_decrement);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% BOUNDARY CONDITIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
BC = {"MUR","MUR","MUR","MUR","MUR","MUR"};
FDTD = SetBoundaryCond( FDTD, BC );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COORDINATE SYSTEM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
CSX = InitCSX('CoordSystem', 0); % Cartesian coordinate system.
mesh.x = []; % mesh variable initialization (Note: x y z implies type Cartesian).
mesh.y = [];
mesh.z = [];
CSX = DefineRectGrid(CSX, unit, mesh); % First call with empty mesh to set deltaUnit attribute.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EXCITATION gauss
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
f0 = 3.0*1000000000.0;
fc = 3.0*1000000000.0;
FDTD = SetGaussExcite( FDTD, f0, fc );
max_res = c0 / (f0 + fc) / 20;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MATERIALS AND GEOMETRY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
CSX = AddMetal( CSX, 'PEC' );

%% MATERIAL - PEC
CSX = AddMetal(CSX, 'PEC');
CSX = ImportSTL(CSX, 'PEC', 9800, [currDir '/copper_gen_model.stl'], 'Transform', {'Scale', fc_unit/unit});

%% MATERIAL - air
CSX = AddMaterial(CSX, 'air');
CSX = SetMaterialProperty(CSX, 'air', 'Epsilon', 1, 'Mue', 1);
CSX = ImportSTL(CSX, 'air', 9600, [currDir '/airbox_gen_model.stl'], 'Transform', {'Scale', fc_unit/unit});

%% MATERIAL - fr4
CSX = AddMaterial(CSX, 'fr4');
CSX = SetMaterialProperty(CSX, 'fr4', 'Epsilon', 4.5, 'Mue', 1);
CSX = ImportSTL(CSX, 'fr4', 9700, [currDir '/prepag_gen_model.stl'], 'Transform', {'Scale', fc_unit/unit});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GRID LINES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% GRID - grid-air - airbox (Fixed Distance)
mesh.x(mesh.x >= -15 & mesh.x <= 65) = [];
mesh.x = [ mesh.x (-15:2:65) ];
mesh.y(mesh.y >= -15 & mesh.y <= 65) = [];
mesh.y = [ mesh.y (-15:2:65) ];
mesh.z(mesh.z >= -8 & mesh.z <= 12) = [];
mesh.z = [ mesh.z (-8:2:12) ];
CSX = DefineRectGrid(CSX, unit, mesh);

%% GRID - grid-prepag - prepag (Fixed Distance)
mesh.x(mesh.x >= 0 & mesh.x <= 50) = [];
mesh.x = [ mesh.x (0:2:50) ];
mesh.y(mesh.y >= 0 & mesh.y <= 50) = [];
mesh.y = [ mesh.y (0:2:50) ];
mesh.z(mesh.z >= 0 & mesh.z <= 1.53) = [];
mesh.z = [ mesh.z (0:0.4:1.53) ];
CSX = DefineRectGrid(CSX, unit, mesh);

%% GRID - grid-copper - copper (Fixed Distance)
mesh.x(mesh.x >= 0.5 & mesh.x <= 49.5) = [];
mesh.x = [ mesh.x (0.5:0.1:49.5) ];
mesh.y(mesh.y >= 0.5005 & mesh.y <= 49.4995) = [];
mesh.y = [ mesh.y (0.5005:0.1:49.4995) ];
mesh.z(mesh.z >= -0.035 & mesh.z <= 1.565) = [];
mesh.z = [ mesh.z (-0.035:0.035:1.565) ];
CSX = DefineRectGrid(CSX, unit, mesh);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PORTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
portNamesAndNumbersList = containers.Map();

%% PORT - in - in
portStart = [ 1, 24.5, -0.035 ];
portStop  = [ 2, 25.5, 1.565 ];
portR = 50;
portUnits = 1;
portExcitationAmplitude = 1.0;
portDirection = [0 0 1]*portExcitationAmplitude;
[CSX port{1}] = AddLumpedPort(CSX, 10000, 1, portR*portUnits, portStart, portStop, portDirection, true);
portNamesAndNumbersList("in") = 1;


%% PORT - out - out
portStart = [ 48, 24.5, -0.035 ];
portStop  = [ 49, 25.5, 1.565 ];
portR = 50;
portUnits = 1;
portExcitationAmplitude = 1.0;
portDirection = [0 0 1]*portExcitationAmplitude;
[CSX port{2}] = AddLumpedPort(CSX, 9900, 2, portR*portUnits, portStart, portStop, portDirection);
portNamesAndNumbersList("out") = 2;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PROBES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% PROBE - efield - efield
dumpboxType = 0;
CSX = AddDump(CSX, 'efield_efield', 'DumpType', dumpboxType);
dumpboxStart = [ -15, -15, 1.55 ];
dumpboxStop  = [ 65, 65, 1.55 ];
CSX = AddBox(CSX, 'efield_efield', 0, dumpboxStart, dumpboxStop );


%% PROBE - efield-3d - airbox
dumpboxType = 0;
CSX = AddDump(CSX, 'efield-3d_airbox', 'DumpType', dumpboxType);
dumpboxStart = [ -15, -15, -8 ];
dumpboxStop  = [ 65, 65, 12 ];
CSX = AddBox(CSX, 'efield-3d_airbox', 0, dumpboxStart, dumpboxStop );


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RUN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
WriteOpenEMS( [Sim_Path '/' Sim_CSX], FDTD, CSX );
CSXGeomPlot( [Sim_Path '/' Sim_CSX] );

if (postprocessing_only==0)
    %% run openEMS
    RunOpenEMS( Sim_Path, Sim_CSX, openEMS_opts );
end
