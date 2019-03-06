module PartedArrays

export
        BlockArray,
        BlockMatrix,
        BlockVector,
        create_partition,
        create_partition2

    include("partitioning.jl")

    import Base: size, getindex, setindex!, length, IndexStyle, +, -, getfield

    struct BlockArray{T,N} <: AbstractArray{T,N}
        A::AbstractArray{T,N}
        parts::NamedTuple
    end
    function BlockArray(A::AbstractMatrix,lengths::NTuple{N,Int},names::NTuple{N,Symbol}) where {N,T}
        parts = create_partition2(lengths,names)
        BlockArray(A,parts)
    end
    function BlockArray(A::AbstractVector,lengths::NTuple{N,Int},names::NTuple{N,Symbol}) where {N,T}
        parts = create_partition(lengths,Tuple(names))
        BlockArray(A,parts)
    end
    BlockArray(A::AbstractArray,lengths::Vector{Int},names::Vector{Symbol}) = BlockArray(A,Tuple(lengths),Tuple(names))
    BlockVector{T} = BlockArray{T,1}
    BlockMatrix{T} = BlockArray{T,2}

    size(A::BlockArray) = size(A.A)
    getindex(A::BlockArray, i::Int) = getindex(A.A, i)
    getindex(A::BlockArray, I::Vararg{Int, 2}) where N = A.A[I[1],I[2]]
    getindex(A::BlockArray, I...) = getindex(A.A, I...)
    setindex!(A::BlockArray, I...) = setindex!(A.A, I...)
    setindex!(A::BlockArray, v, i::Int) = setindex!(A.A, v, i)
    setindex!(A::BlockArray, v, I::Vararg{Int, N}) where N = A.A[I[1],I[2]] = v
    IndexStyle(::BlockArray) = IndexCartesian()
    length(A::BlockArray) = length(A.A)
    Base.show(io,A::BlockArray) = show(io,A.A)
    Base.show(io::IO, T::MIME{Symbol("text/plain")}, X::BlockMatrix) = show(io, T::MIME"text/plain", X.A)
    +(A::BlockArray,B::Matrix) = A.A + B
    +(B::Matrix,A::BlockArray) = A.A + B
    getindex(A::BlockArray, p::Symbol) = view(A.A,getfield(A.parts,p)...)
    getindex(A::BlockVector, p::Symbol) = view(A.A,getfield(A.parts,p))
    function Base.getproperty(A::BlockArray{T,N}, p::Symbol) where {T,N}
        if p == :A || p == :parts
            getfield(A,p)
        else
            if N == 1
                return view(getfield(A,:A), getfield(getfield(A,:parts),p))
            else
                return view(getfield(A,:A), getfield(getfield(A,:parts),p)...)
            end
        end
    end

end # module