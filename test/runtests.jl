using UnitParser
using Test

@testset "UnitParser.jl" begin
    @test reduce_units_expr("meter/seconds") == "m*s^-1"
    @test reduce_units_expr("meter seconds^-1") == "m*s^-1"
    @test reduce_units_expr("nanometers3 / microsecond") == "nm^3*μs^-1"
    @test reduce_units_expr("volt^2/kiloamp") == "V^2*kA^-1"
    @test reduce_units_expr("milligram/metres2") == "mg*m^-2"
end
