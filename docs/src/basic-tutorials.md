# Tutorial

Below is a quick tutorial to help get you started. Note that we assume you have [Julia](https://julialang.org/) installed and configured already.

## Getting Makie

```julia
add Makie
```

## Getting latest version of Makie

```Julia
add Makie#master AbstractPlotting#master GLMakie#master
test Makie
```

The first use of Makie might take a little bit of time, due to precompilation.

## Set the `Scene`

The `Scene` object holds everything in a plot, and you can initialize it by doing so:

```julia
scene = Scene()
```

Note that before you put anything in the scene, it will be black!

## Basic plotting

Below are some examples of basic plots to help you get oriented.

You can put your in the plot window and scroll to zoom. Right click and drag lets you pan around the scene, and left click and drag lets you do selection zoom (in 2D plots), or orbit around the scene (in 3D plots).

Many of these examples also work in 3D.

### Scatter plot

@example_database("Tutorial simple scatter")

@example_database("Tutorial markersize")

### Line plot

@example_database("Tutorial simple line")

### Adding a title

@example_database("Tutorial title")

### Adding to a scene

@example_database("Tutorial adding to a scene")

### Adjusting scene limits

@example_database("Tutorial adjusting scene limits")

### Basic theming

@example_database("Tutorial basic theming")

## Controlling display programatically

`Scene`s will only display by default in global scope.  To make a Scene display when it's defined in a local scope,
like a function or a module, you can call `display(scene)`, which will automatically display it in the best available
display.  
You can force display to the backend's preferred window by calling `display(AbstractPlotting.PlotDisplay(), scene)`.

## Saving plots

See the [Output](@ref) section.

## Animation

See the [Animation](@ref) section, as well as the [Interaction](@ref) section.

## More examples

See the [Example Gallery](https://simondanisch.github.io/ReferenceImages/gallery/index.html).
