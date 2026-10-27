using System.Security.Claims;
using BookingApi.Auth;
using BookingApi.Common;

namespace BookingApi.Bookings;

public static class BookingEndpoints
{
    public static void MapBookingEndpoints(this IEndpointRouteBuilder app)
    {
        var bookings = app.MapGroup("/bookings").RequireAuthorization();

        bookings.MapGet("/{id:guid}", async (Guid id, ClaimsPrincipal user, BookingService service, CancellationToken ct) =>
            ToHttp(await service.GetAsync(Member.From(user), id, ct),
                booking => TypedResults.Ok(BookingResponse.From(booking))));

        bookings.MapPost("/", async (CreateBookingRequest request, ClaimsPrincipal user, BookingService service, CancellationToken ct) =>
            ToHttp(await service.CreateAsync(Member.From(user), request, ct),
                booking => TypedResults.Created($"/bookings/{booking.Id}", BookingResponse.From(booking))));
    }

    // The one place where a Result becomes an HTTP response. Another member's booking is a
    // 404, not a 403, so callers cannot tell whether it exists.
    private static IResult ToHttp<T>(Result<T> result, Func<T, IResult> onSuccess) =>
        result.IsSuccess
            ? onSuccess(result.Value)
            : result.Error.Kind switch
            {
                ErrorKind.NotFound => TypedResults.NotFound(),
                ErrorKind.Validation => TypedResults.Problem(result.Error.Message, statusCode: StatusCodes.Status400BadRequest),
                _ => TypedResults.Problem(statusCode: StatusCodes.Status500InternalServerError),
            };
}
