using BookingApi.Auth;
using BookingApi.Bookings;
using BookingApi.Pricing;

var builder = WebApplication.CreateBuilder(args);

builder.Services
    .AddAuthentication(DemoApiKeyHandler.SchemeName)
    .AddScheme<DemoApiKeyOptions, DemoApiKeyHandler>(DemoApiKeyHandler.SchemeName,
        options => builder.Configuration.GetSection("DemoAuth").Bind(options));
builder.Services.AddAuthorization();
builder.Services.AddProblemDetails();

builder.Services.AddSingleton<IBookingRepository, InMemoryBookingRepository>();
builder.Services.AddSingleton<IPricingStrategy, StandardPricing>();
builder.Services.AddSingleton<IPricingStrategy, PremiumPricing>();
builder.Services.AddSingleton<PricingStrategySelector>();
builder.Services.AddScoped<BookingService>();

var app = builder.Build();

// Bugs become a generic 500 with no internal details (ADR-006).
app.UseExceptionHandler();
app.UseAuthentication();
app.UseAuthorization();

app.MapBookingEndpoints();

app.Run();

public partial class Program;
