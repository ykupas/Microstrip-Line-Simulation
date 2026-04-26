# Microstrip Coplanar Waveguide Simulation

This project aims to simulate the behavior and electrical parameters of a microstrip coplanar waveguide using the KiCAD v9.0.6 design software, the FreeCAD 1.0.2 modeling software, and the OpenEMS, Emerge, and Elmer FEM software for electromagnetic simulations.

## Design

Using the KiCAD calculator, we arrived at the following results for the coplanar microstrip waveguide:

![calculator](img/calculator.png)

As configured in the calculation, the stack-up used was:

![stackup](img/stackup.png)

Using 1.5mm pads, the final design can be seen as following:

![pcb-design](img/pcb-design.png)

## Modeling

After the project is completed in KiCAD, it is imported into FreeCAD, adding an air box, an PortIn and PortOut, and .ini files for configuring the generation of simulation scripts.

![3d-model](img/3d-model.png)
