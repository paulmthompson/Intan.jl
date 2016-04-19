
#=
Filters and Decoding Algorithms


=#

abstract Filter

#=
Weiner Filter

Linear Regression between firing rate and kinematics after some training period.
=#

type Weiner <: Filter
    taps::FloatRange{Float64}
    period::Int64
    train_s::Array{Float64,2}
    train_k::Array{Float64,1}
    coeffs::Array{Float64,2}
end

function Weiner(rhd::RHD2000,ntaps::FloatRange{Float64},x::Int64,y::Int64,z::Int64)
    n=length(ntaps)
    per=ntaps.step/ntaps.divsor*rhd.sampleRate
    Weiner(ntaps,per,zeros(Float64,x,n*y+1),zeros(Float64,x,z),zeros(Float64,n*y+1,z))
end

Weiner(rhd::RHD2000,x::Int64,y::Int64,z::Int64)=Weiner(rhd,0.0:.1:0.0,x,y,z)

function train!(rhd::RHD2000,w::Weiner)
end


#=
Kalman Filter
=#
#=
type Kalman <: Filter
end
=#

#=
Unscented Kalman Filter
=#
#=
type UKF <: Filter
end
=#

#=
Re-Fit
=#

#=
Population Vector
=#
