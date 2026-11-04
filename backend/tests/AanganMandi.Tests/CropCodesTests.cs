using AanganMandi.Application.Master;

namespace AanganMandi.Tests;

public class CropCodesTests
{
    private static readonly HashSet<string> Known = ["TOMATO", "BANANA"];

    [Fact]
    public void Master_codes_and_custom_names_pass_in_order()
    {
        var (codes, error) = CropCodes.Normalize(["TOMATO", "custom:Kakarakaya", "BANANA"], Known);
        Assert.Null(error);
        Assert.Equal(["TOMATO", "custom:Kakarakaya", "BANANA"], codes);
    }

    [Fact]
    public void Custom_names_in_Telugu_and_Hindi_are_accepted()
    {
        var (codes, error) = CropCodes.Normalize(["custom:కాకరకాయ", "custom:करेला"], Known);
        Assert.Null(error);
        Assert.Equal(2, codes!.Length);
    }

    [Fact]
    public void Custom_names_are_tidied_and_deduplicated_ignoring_case()
    {
        var (codes, error) = CropCodes.Normalize(["custom:  Sweet   tamarind ", "custom:sweet tamarind", "TOMATO", "TOMATO"], Known);
        Assert.Null(error);
        Assert.Equal(["custom:Sweet tamarind", "TOMATO"], codes);
    }

    [Theory]
    [InlineData("POTATO")] // not in the master list
    [InlineData("custom:")] // empty
    [InlineData("custom:A")] // too short
    [InlineData("custom:1234")] // not letters
    [InlineData("custom:<script>")]
    [InlineData("custom:This name is far too long to be a crop")]
    public void Invalid_codes_are_rejected(string code)
    {
        var (codes, error) = CropCodes.Normalize([code], Known);
        Assert.Null(codes);
        Assert.NotNull(error);
    }

    [Fact]
    public void At_most_30_crops()
    {
        var many = Enumerable.Range(0, 31).Select(i => $"custom:Crop {(char)('a' + i % 26)}{(char)('a' + i / 26)}");
        Assert.NotNull(CropCodes.Normalize(many, Known).Error);
    }
}
