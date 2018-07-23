using Base.Broadcast

@inline function Base.copyto!(dest::GPUArray, bc::Broadcast.Broadcasted{Nothing})
    axes(dest) == axes(bc) || Broadcast.throwdm(axes(dest), axes(bc))
    # # Performance optimization: broadcast!(identity, dest, A) is equivalent to copyto!(dest, A) if indices match
    # if bc.f === identity && bc.args isa Tuple{AbstractArray} # only a single input argument to broadcast!
    #     A = bc.args[1]
    #     if axes(dest) == axes(A)
    #         return copyto!(dest, A)
    #     end
    # end
    bc′ = Broadcast.preprocess(dest, bc)
    gpu_call(dest, (dest, bc′)) do state, dest, bc′
        let I = CartesianIndex(@cartesianidx(dest))
            @inbounds dest[I] = bc′[I]
        end
    end

    return dest
end

function mapidx(f, A::GPUArray, args::NTuple{N, Any}) where N
    gpu_call(A, (f, A, args)) do state, f, A, args
        ilin = @linearidx(A, state)
        f(ilin, A, args...)
    end
end
