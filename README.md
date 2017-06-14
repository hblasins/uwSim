# Underwater Image Systems Simulation

Digital cameras are ubiquitus and are slowly finding their way in niche application areas, such
as imaging below the surface of the sea. Underwater imaging is becoming popular among
consumers (GoPro action cameras) as well as professionals (underwater exploration). 

Underwater imaging faces many more challenges than imaging on the ground, for example excessive 
absorption of the red light component or sever backscattering. Realistic simulations enable 
to explore some of those limitations without the need for troublesome experiments.

This project provides a set of tools to realisticly simualte the appearance of underwater scenes
in a variety of water conditions. Simulated images faciliate evaluation, and comparisons across 
different underwater imaing systems and correction algorithms.

If you use these tools please cite the following
```
@inproceedings{blasinski2017cmf,
    title={Underwater Image Systems Simulation},
    author={Blasinski, Henryk and Lian, Trisha and Farrell, Joyce},
    booktitle={Imaging and Applied Optics Congress},
    year={2017},
    organization={OSA}
}
```

## Dependencies

To succesffuly run the scripts in this project the following dependencies need to be 
installed.

* [RenderToolbox4](http://rendertoolbox.org) - a set of Matlab tools to create, manipulate and
render complex 3D scene files.
* [Docker](https://www.docker.com) - RenderToolbox4 uses either Mitsuba or PBRT renderers to 
produce final images. Rather than install these programs we provide their dockerized implementations.
A cross-platform Docker engine is required to run these.
* [CVX](http://cvxr.com/) - a Matlab toolbox for convex optimization.
* [ISET](http://imageval.com) - Image Systems Engineering Toolbox for camera sensor simulations.

## Data

In order to reproduce the results from our publications please download the input data (underwater
images, 3D models) from [Stanford Digital Repository].

## Installation

Please clone the repository to your local drive. From MATLAB run `Code/install.m` function 
to correctly set up MATLAB PATH in your environment. 

## Directory structure

* **Code** contains all the Matlab source code
* **Parameters** contains calibration data for different cameras and light sources. For example
the spectral responsivities of the Canon G7X used in the experiments.
* **Scenes** 3D scene files used in simulations. We usually generate these scenes in [Blender](https://www.blender.org)
