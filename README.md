# UnitParser.jl

Small implementation of general unit parsing.

The basic function is `parse_units`, transforming a string into a `Unitful` unit.

```julia
julia> parse_units("nanoamps3 seconds / micrometer^2")
nA^3 s μm^-2
```

At its core this package just transform a complicated string to one that
`Unitful` can parse.
You can get that simpler string by using `reduce_units expr`.

```julia
julia> using Unitful

julia> s = reduce_units_expr("kilometers / m^2")
"km*m^-2"

julia> uparse(s)
km m^-2
```