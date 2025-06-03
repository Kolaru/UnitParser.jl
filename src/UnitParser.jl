module UnitParser

export parse_units, destructure_units, reduce_units_expr, short_form

using RelocatableFolders
using Unitful
using YAML

const ALIASES = @path joinpath(@__DIR__, "aliases.yaml")

const aliases_data = open(ALIASES) do file
    YAML.load(file)
end
const prefixes = aliases_data["prefixes"]
const aliases = aliases_data["units"]

const r_integer = r"(-?[0-9]+)"  # Integers
const r_unit_name = r"([A-Za-zμΩ]+)"  # Names of units including prefixes
const r_power = r" *(?:\*\*|\^)? *"  # Power symbols
const r_divide = r" *(?:/|per|PER) *"  # Division symbols
const r_multiply = r" *[\*\. ] *"  # Multiplication symbols

"""
    consume(str, m::RegexMatch)

Remove the matching part of the RegexMatch and return the remaining string.
"""
consume(str, m::RegexMatch) = str[sizeof(m.match)+1:end]
consume(str, ::Nothing) = str

match_start(pattern, str) = match(r"^" * pattern, str)


function parse_units(str::AbstractString ; unit_context = Unitful)
    return uparse(reduce_units_expr(str) ; unit_context)
end


function reduce_units_expr(str::AbstractString)
    factors = String[]
    for (prefix, core, exponent) in destructure_units(str)
        if exponent != 1
            factor = "$prefix$core^$exponent"
        else
            factor = "$prefix$core"
        end
        push!(factors, factor)
    end
    return join(factors, "*")
end


"""
    destructure_units(str)

Deconstruct a str representing units into a list of (prefix, name, exponent),
one for each factor.
"""
function destructure_units(str::AbstractString)
    str, factors = destructure_factors(str)
    str = consume(str, match_start(r_divide, str))
    str, divisors = destructure_factors(str)

    if length(str) > 0
        throw(ArgumentError("The input str $str could not be fully parsed"))
    end

    divisors = map(divisors) do (prefix, symbol, exponent)
        (prefix, symbol, -exponent)
    end

    append!(factors, divisors)
    return factors
end


function destructure_factors(str::AbstractString)
    factors = []
    while (match_start(r_divide, str) === nothing &&
          (m = match_start(r_unit_name, str)) !== nothing)
        unit_name = m.match
        str = consume(str, m)

        if (m = match_start(r_power * r_integer, str)) !== nothing
            str = consume(str, m)
            exponent = parse(Int, m.captures[1])
        else
            exponent = 1
        end

        push!(factors, (short_form(unit_name)..., exponent))

        str = consume(str, match_start(r_multiply, str))
    end

    return str, factors
end


"""
    short_form(unit_name::AstractString)

Reduce the natural name of a units to its symbolic form for prefix and name.

If no match is found, return the original str.

Example
=======
julia> short_form("micrometers")
("μ", "m")

Return
======
unit_prefix: String
    Short form representing the prefix of the units, e.g. "k" for "kilo".
    Set to empty str if the units had no prefix.

core_unit: String
    Short form representing the units, e.g. "A" for "ampere".
"""
function short_form(unit_name::AbstractString)
    unit_name = lowercase(unit_name)

    length(unit_name) == 1 && return ("", unit_name)
    length(unit_name) == 2 && return (string(first(unit_name)), string(unit_name[nextind(unit_name, 1)]))

    # Remove trailing 's' to account for pluralized units
    if unit_name[end] == 's'
        unit_name = unit_name[1:end-1]
    end

    unit_prefix = ""

    for (prefix, symbol) in prefixes
        n = length(prefix)
        if length(unit_name) >= n && unit_name[1:n] == prefix
            unit_prefix = symbol
            unit_name = unit_name[n+1:end]
            break
        end
    end

    core_unit = unit_name

    for (alias, symbol) in aliases
        if unit_name == alias
            core_unit = symbol
            break
        end
    end

    return unit_prefix, core_unit
end

end # module
