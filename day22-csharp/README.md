# Overview

Solution to https://adventofcode.com/2021/day/22 in [C#](https://dotnet.microsoft.com/en-us/languages/csharp).

To build and run:

- Install the .NET framework `F#` by follwing the instructions at https://docs.microsoft.com/en-us/dotnet/core/install/linux?WT.mc_id=dotnet-35129-website/. There are various installation methods, I used the install script.
- `dotnet run`

`dotnet` framework version: `6.0.100`

# Algorithm

The naive approach of counting all the "on" cubes and keeping them in a map doesn't work due to the very large input space, so the algorithm uses a few basic 3D geometry concepts and builds a list of "on" cubes in the 3D space (these are not the same cubes as the puzzle cubes, but a 3D area defined by a (xmin, xmax), (ymin, ymax), (zmin, zmax) pair). Then the algorithm considers all cubes in the input and their intersections with existing cubes, adding/removing/splitting cubes as needed and making sure that any single "on pixel" (discrete coordinate in the 3D space) belongs to a single cube:

- Regardless of the kind of cube that is being added ("on" or "off"), it removes parts of all the cubes that it intersects.
- If the cube was an "on" cube, it is added back to the list of cubes, otherwise it is forgotten.

After processing all the cubes in the input and intersecting them, the sum of the volumes of the remaining cubes is the solution output.