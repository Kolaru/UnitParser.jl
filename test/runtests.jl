using UnitParser
using Unitful
using Test

@testset "UnitParser.jl" begin
    @testset "General" begin
        @test reduce_units_expr("meter/seconds") == "m*s^-1"
        @test reduce_units_expr("meter seconds^-1") == "m*s^-1"
        @test reduce_units_expr("nanometers3 / microsecond") == "nm^3*μs^-1"
        @test reduce_units_expr("volt^2/kiloamp") == "V^2*kA^-1"
        @test reduce_units_expr("milligram/metres2") == "mg*m^-2"
    end

    @testset "Seconds" begin
        @test short_form("ms") == ("m", "s")
        @test reduce_units_expr("ms") == "ms"
        @test parse_units("ms") == u"ms"
        @test short_form("s") == ("", "s")
        @test reduce_units_expr("m s") == "m*s"
        @test parse_units("m s") == u"m*s"
    end

    @testset "Micrometer (unicode)" begin
        @test short_form("μm") == ("μ", "m")
        @test reduce_units_expr("μm") == "μm"
        @test parse_units("μm") == u"μm" 
        @test parse_units("micrometers") == u"μm"
    end
end