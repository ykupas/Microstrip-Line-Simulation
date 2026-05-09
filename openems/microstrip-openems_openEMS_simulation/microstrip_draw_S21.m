% Plot S11, S21 parameters from OpenEMS results.
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

Sim_Path = 'simulation_output';
currDir = strrep(pwd(), '\', '\\');
display(currDir);

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
max_res = c0 / (f0 + fc) / 20;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MATERIALS AND GEOMETRY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
CSX = AddMetal( CSX, 'PEC' );

%% MATERIAL - PEC
CSX = AddMetal(CSX, 'PEC');

%% MATERIAL - air
CSX = AddMaterial(CSX, 'air');
CSX = SetMaterialProperty(CSX, 'air', 'Epsilon', 1, 'Mue', 1);

%% MATERIAL - fr4
CSX = AddMaterial(CSX, 'fr4');
CSX = SetMaterialProperty(CSX, 'fr4', 'Epsilon', 4.5, 'Mue', 1);

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
% POST-PROCESSING AND PLOT GENERATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

freq = linspace( max([0,f0-fc]), f0+fc, 501 );
port = calcPort( port, Sim_Path, freq);

s11 = port{1}.uf.ref./ port{1}.uf.inc;
s21 = port{2}.uf.ref./ port{1}.uf.inc;

s11_dB = 20*log10(abs(s11));
s21_dB = 20*log10(abs(s21));

plot(freq/1e9,s11_dB,'k-','LineWidth',2);
hold on;
grid on;
plot(freq/1e9,s21_dB,'r--','LineWidth',2);
legend('S_{11}','S_{21}');
ylabel('S-Parameter (dB)','FontSize',12);
xlabel('frequency (GHz)','FontSize',12);
ylim([-40 2]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SAVE PLOT DATA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

save_plot_data = 0;

if (save_plot_data != 0)
	mfile_name = mfilename('fullpath');
	[pathstr,name,ext] = fileparts(mfile_name);
	output_fn = strcat(pathstr, '/', name, '.csv')
	
	%% write header to file
	textHeader = '#f(Hz)\tS11(dB)\tS21(dB)';
	fid = fopen(output_fn, 'w');
	fprintf(fid, '%s\n', textHeader);
	fclose(fid);
	
	%% write data to end of file
	dlmwrite(output_fn, [abs(freq)', s11_dB', s21_dB'],'delimiter','\t','precision',6, '-append');
end

