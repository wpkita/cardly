using Microsoft.AspNetCore.Mvc.Testing;

namespace Cardly.Api.Tests;

public class WeatherForecastTests(WebApplicationFactory<Program> factory) : IClassFixture<WebApplicationFactory<Program>>
{
    [Fact]
    public async Task GetWeatherForecast_ReturnsOk()
    {
        var client = factory.CreateClient();

        var response = await client.GetAsync("/weatherforecast");

        Assert.Equal(System.Net.HttpStatusCode.OK, response.StatusCode);
    }
}
