module UnitParser

using StringParserPEG
using YAML


units_grammar = Grammar("""
    start => (product & divisor {liftchild}) {(r,v,f,l,c) -> [c[1]..., c[2]...]} | product {liftchild}
    divisor => (-(divide) & product) {(r,v,f,l,c) -> [(cc[1], -cc[2]) for cc in c[1]]}
    divide => *(space) & divide_op & *(space)
    divide_op => '/' | 'per' | 'PER'
    product => (unit & +(factor)) {(r,v,f,l,c) -> [c[1], c[2].children...]} | unit {(r,v,f,l,c) -> c}
    factor => (-(multiply) & !(divide) & unit {liftchild}) {liftchild}
    multiply => *(space) & multiply_op & *(space) | +(space)
    multiply_op => '.' | '*' | '-'
    unit => (name & power) {(r,v,f,l,c) -> (c[1], c[2])} | name {(r,v,f,l,c) -> (c[1], 1)}
    power => (-(?(raise)) & int) {(r,v,f,l,c) -> parse(Int, c[1].value)}
    raise => '^' | '**'
    name => (r([A-Za-zμ]+)r) {(r,v,f,l,c) -> v}
    space => ' '
    int => r(-?[0-9]+)r
""")

aliases_data = YAML.load(open("aliases.yaml"))
prefixes = aliases_data["prefixes"]
aliases = aliases_data["units"]

to_unitful(units_string) = join_symbols(to_symbols(units_string))


"""
    join_symbols(symbol_tuples::Vector{Tuple})
"""
function join_symbols(symbol_tuples)
    units = map(symbol_tuples) do tuple
        if tuple[2] == 1
            return tuple[1]
        else
            return join([tuple[1], "^", tuple[2]])
        end
    end

    return join(units, "*")
end

"""
    to_symbols(units_string::AbstractString)
"""
function to_symbols(units_string::AbstractString)
    raw_units, _, err = parse(units_grammar, units_string)
    new_units = []

    for units in raw_units
        if isa(units, Tuple)
            push!(new_units, (reduce_units(units[1]), units[2]))
        else
            push!(new_units, reduce_units(units))
        end
    end

    return new_units
end

"""
    reduce_units(units_name::AstractString)

Reduce the natural name of a units to its symbolic form for prefix and name.

If not match is found, return the original string.

Example
=======
julia> reduce_units("micrometers")
("μ", "m")

Return
======
units_prefix: String
    Short form representing the prefix of the units, e.g. "k" for "kilo".
    Set to empty string if the units had no prefix.

core_units: String
    Short form representing the units, e.g. "A" for "ampere".
"""
function reduce_units(units_name::AbstractString)
    units_name = lowercase(units_name)

    # Remove trailing 's' to account for pluralized units
    if units_name[end] == 's'
        units_name = units_name[1:end-1]
    end

    units_prefix = ""

    for (prefix, symbol) in prefixes
        n = length(prefix)
        if length(units_name) >= n && units_name[1:n] == prefix
            units_prefix = symbol
            units_name = units_name[n+1:end]
            break
        end
    end

    core_units = units_name

    for (alias, symbol) in aliases
        if units_name == alias
            core_units = symbol
            break
        end
    end

    return units_prefix*core_units
end

end # module
