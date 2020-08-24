using StringParserPEG
using YAML

grammar = Grammar("""
    start => (product & divisor {liftchild}) {(r,v,f,l,c) -> [c[1]..., c[2]...]} | product {liftchild}
    divisor => (-(divide) & product) {(r,v,f,l,c) -> [(cc[1], -cc[2]) for cc in c]}
    divide => *(space) & divide_op & *(space)
    divide_op => '/' | 'per' | 'PER'
    product => (unit & +(factor)) {(r,v,f,l,c) -> [c[1], c[2].children...]} | unit {(r,v,f,l,c) -> c}
    factor => (-(multiply) & !(divide) & unit {liftchild}) {liftchild}
    multiply => *(space) & multiply_op & *(space) | +(space)
    multiply_op => '.' | '*' | '-'
    unit => (name & power) {(r,v,f,l,c) -> (c[1], c[2])} | name {liftchild}
    power => (-(?(raise)) & int) {(r,v,f,l,c) -> parse(Int, c[1].value)}
    raise => '^' | '**'
    name => (r([A-Za-zμ]+)r) {(r,v,f,l,c) -> v}
    space => ' '
    int => r(-?[0-9]+)r
""")

data = YAML.load(open("aliases.yaml"))
prefixes = data["prefixes"]
aliases = data["units"]


function to_unit_symbols(s)
    units, _, err = parse(grammar, s)
    new_units = []
    println(units)

    for u in units
        push!(new_units, process_units(u))
    end

    return new_units
end

function process_units(name::AbstractString)
    if name[end] == "s"
        name = name[1:end-1]
    end

    pre = ""
    println(name)

    for (prefix, sym) in prefixes
        n = length(prefix)
        if length(name) >= n && name[1:n] == prefix
            pre = sym
            name = name[n+1:end]
            break
        end
    end

    short_name = name

    for (alias, sym) in aliases
        if name == alias
            short_name = sym
            break
        end
    end

    return pre * short_name
end

function process_units(tuple::Tuple)
    println(tuple)
    return process_units(tuple[1]), tuple[2]
end