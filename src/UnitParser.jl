module UnitParser

export parse_units

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


"""
    parse_units(string)

Parse a string representing units and parse it into a list of individual
units represented as a tuple (prefix, name, exponent).
"""
function parse_units(string)
    string, factors = parse_factors(string)
    string = consume(string, match(r"^" * r_divide, string))
    string, divisors = parse_factors(string)

    if length(string) > 0
        @error "The input string could not be fully parsed"
    end

    divisors = map(divisors) do (prefix, symbol, exponent)
        (prefix, symbol, -exponent)
    end

    append!(factors, divisors)
    return factors
end


function parse_factors(string)
    factors = []
    while (m = match(r"^" * r_unit_name, string)) !== nothing
        unit_name = m.match
        match(r"^" * r_divide, unit_name) !== nothing && break
        string = consume(string, m)

        if (m = match(r"^" * r_power * r_integer, string)) !== nothing
            string = consume(string, m)
            exponent = parse(Int, m.captures[1])
        else
            exponent = 1
        end

        push!(factors, (reduce_units(unit_name)..., exponent))

        string = consume(string, match(r"^" * r_multiply, string))
    end

    return string, factors
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

    return units_prefix, core_units
end

end # module
