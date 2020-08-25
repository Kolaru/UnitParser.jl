module UnitParser

export destructure_units, reduce_units_expr

using YAML

const aliases_data = YAML.load(open("src/aliases.yaml"))
const prefixes = aliases_data["prefixes"]
const aliases = aliases_data["units"]

const r_integer = r"(-?[0-9]+)"
const r_unit_name = r"([A-Za-zμ]+)"
const r_power = r" *(?:\*\*|\^)? *"
const r_divide = r" *(?:/|per|PER) *"
const r_multiply = r" *[\*\. ] *"

"""
    consume(string, m::RegexMatch)

Remove the matching part of the RegexMatch and return the shorter string.
"""
consume(string, m::RegexMatch) = string[length(m.match)+1:end]
consume(string, ::Nothing) = string

match_start(pattern, string) = match(r"^" * pattern, string)


function reduce_units_expr(string::AbstractString)
    factors = []
    for (prefix, core, exponent) in destructure_units(string)
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
    destructure_units(string)

Deconstruct a string representing units into a list of (prefix, name, exponent),
one for each factor.
"""
function destructure_units(string::AbstractString)
    string, factors = destructure_factors(string)
    string = consume(string, match_start(r_divide, string))
    string, divisors = destructure_factors(string)

    if length(string) > 0
        @error "The input string could not be fully parsed"
    end

    divisors = map(divisors) do (prefix, symbol, exponent)
        (prefix, symbol, -exponent)
    end

    append!(factors, divisors)
    return factors
end


function destructure_factors(string::AbstractString)
    factors = []
    while (match_start(r_divide, string) === nothing &&
          (m = match_start(r_unit_name, string)) !== nothing)
        unit_name = m.match
        string = consume(string, m)

        if (m = match_start(r_power * r_integer, string)) !== nothing
            string = consume(string, m)
            exponent = parse(Int, m.captures[1])
        else
            exponent = 1
        end

        push!(factors, (short_form(unit_name)..., exponent))

        string = consume(string, match_start(r_multiply, string))
    end

    return string, factors
end


"""
    short_form(units_name::AstractString)

Reduce the natural name of a units to its symbolic form for prefix and name.

If no match is found, return the original string.

Example
=======
julia> short_form("micrometers")
("μ", "m")

Return
======
unit_prefix: String
    Short form representing the prefix of the units, e.g. "k" for "kilo".
    Set to empty string if the units had no prefix.

core_unit: String
    Short form representing the units, e.g. "A" for "ampere".
"""
function short_form(units_name::AbstractString)
    units_name = lowercase(units_name)

    # Remove trailing 's' to account for pluralized units
    if units_name[end] == 's'
        units_name = units_name[1:end-1]
    end

    unit_prefix = ""

    for (prefix, symbol) in prefixes
        n = length(prefix)
        if length(units_name) >= n && units_name[1:n] == prefix
            unit_prefix = symbol
            units_name = units_name[n+1:end]
            break
        end
    end

    core_unit = units_name

    for (alias, symbol) in aliases
        if units_name == alias
            core_unit = symbol
            break
        end
    end

    return unit_prefix, core_unit
end

end # module
