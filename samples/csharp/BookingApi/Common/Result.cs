using System.Diagnostics.CodeAnalysis;

namespace BookingApi.Common;

public enum ErrorKind { Validation, NotFound }

public sealed record Error(ErrorKind Kind, string Message);

// Expected failures are returned, not thrown (ADR-006). Exceptions are for bugs only.
public sealed class Result<T>
{
    private Result(T? value, Error? error)
    {
        Value = value;
        Error = error;
    }

    public T? Value { get; }
    public Error? Error { get; }

    [MemberNotNullWhen(true, nameof(Value))]
    [MemberNotNullWhen(false, nameof(Error))]
    public bool IsSuccess => Error is null;

    public static Result<T> Success(T value) => new(value, null);
    public static Result<T> Failure(Error error) => new(default, error);
}
