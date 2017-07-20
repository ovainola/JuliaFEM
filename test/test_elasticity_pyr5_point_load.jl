# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/JuliaFEM.jl/blob/master/LICENSE.md

using JuliaFEM
using JuliaFEM.Preprocess
using JuliaFEM.Testing

@testset "test Pyr5 elasticity with point load" begin
    nodes = Dict{Int64, Node}(
        1 => [-1.0,-1.0,-1.0],
        2 => [ 1.0,-1.0,-1.0],
        3 => [ 1.0, 1.0,-1.0],
        4 => [-1.0, 1.0,-1.0],
        5 => [ 0.0, 0.0, 1.0])

    element1 = Element(Pyr5, [1, 2, 3, 4, 5])
    baseQuad = Element(Quad4, [1, 2, 3, 4])
    tipPoint = Element(Poi1, [5,])

    update!([element1,baseQuad,tipPoint], "geometry", nodes)
    update!([element1], "youngs modulus", 288.0)
    update!([element1], "poissons ratio", 1/3)

    update!([tipPoint], "displacement traction force 1",  5.0)
    update!([tipPoint], "displacement traction force 2", -7.0)
    update!([tipPoint], "displacement traction force 3",  3.0)

    elasticity_problem = Problem(Elasticity, "solve continuum block", 3)
    elasticity_problem.properties.finite_strain = false
    push!(elasticity_problem, element1, baseQuad, tipPoint)

    baseQuad["displacement 1"] = 0.0
    baseQuad["displacement 2"] = 0.0
    baseQuad["displacement 3"] = 0.0
    boundary_problem = Problem(Dirichlet, "Boundary conditions", 3, "displacement")
    push!(boundary_problem, baseQuad)

    solver = LinearSolver(elasticity_problem, boundary_problem)
    solver()

    disp = element1("displacement", [0.0, 0.0, 1.0], 0.0)
    info("########################################################")
    info("displacement at tip: $disp")
    # Code_Aster Result in verification/2017-05-27-pyramids/Pyr5_displacement.txt
    u_expected = [6.9444444444427100E-02,-9.7222222222197952E-02,1.0416666666679683E-02]
    @test isapprox(disp, u_expected)
end
