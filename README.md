# Underwater Camera Simulation

This repository contains Matlab scripts that demonstrate how to use physics based ray-tracing
to simulate underwater imaging systems. 




## Dependencies

To succesffuly run the scripts in this project the following dependencies need to be 
installed.

* [RenderToolbox4](http://rendertoolbox.org) - a set of Matlab tools to create, manipulate and
render complex 3D scene files.
* [ASSIMP](http://www.assimp.org) - Asset Import Library providing support for reading a variety of 3D scene file formats.
* [Docker](https://www.docker.com) - RenderToolbox4 uses either Mitsuba or PBRT renderers to 
produce final images. Rather than install these programs we provide their dockerized implementations.
A cross-platform Docker engine is required to run these.
* [CVX](http://cvxr.com/) - a Matlab toolbox for convex optimization.
* [ISET](http://imageval.com) - Image Systems Engineering Toolbox for camera sensor simulations.

## Data

In order to reproduce the results from our publications please download the input data from
[Stanford Digital Repository].

## Installation

Please clone the repository to your local drive. From MATLAB run `Code/install.m` function 
to correctly set up MATLAB PATH in your environment. 

## Directory structure

* **Code** contains all the Matlab source code
* **Parameters** contains calibration data for different cameras and light sources. For example
the spectral responsivities of the Canon G7X used in the experiments.
* **Scenes** 3D scene files used in simulations. We usually generate these scenes in [Blender](https://www.blender.org)
