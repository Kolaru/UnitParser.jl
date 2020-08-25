# UnitParser.jl

Small implementation of general unit parsing.

## Example

### Reduction to an expression Unitful.jl can understand

```julia
julia> reduce_units_expr("nanoamps3 seconds / micrometer^2")
"nA^3*s*μm^-2"
```
