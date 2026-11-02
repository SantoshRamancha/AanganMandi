using AanganMandi.Domain.Common;

namespace AanganMandi.Domain.Master;

/// <summary>Crop master data with names in all three app languages.</summary>
public class Crop : Entity
{
    public required string Code { get; set; }
    public required string NameEn { get; set; }
    public required string NameTe { get; set; }
    public required string NameHi { get; set; }
    public string? Icon { get; set; }
    public string? Category { get; set; }
    public string? SeasonMonths { get; set; }
    public decimal YieldPerAcreKg { get; set; }
    public bool GrownInTelangana { get; set; } = true;
}
