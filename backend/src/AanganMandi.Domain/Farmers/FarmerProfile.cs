using AanganMandi.Domain.Common;
using NetTopologySuite.Geometries;

namespace AanganMandi.Domain.Farmers;

public enum VerificationStatus { NotStarted, Pending, Verified, Rejected }

public enum OwnershipType { Owner, Tenant, ForestRights }

/// <summary>Whether the farmer sells only what they grow, or also produce bought from other farmers.</summary>
public enum ProduceSource { OwnFarm, OwnAndOtherFarmers, OtherFarmers }

/// <summary>The one piece of farming evidence the farmer chooses to show.</summary>
public enum EvidenceType { AgriStackFarmerId, LandRecord, FpoMembership, OfficerReference }

/// <summary>
/// MVP verification (after phone OTP): basic farming details + one piece of farming evidence,
/// reviewed by the verifier the farmer is assigned to. Approval sets Level 2 ("Farmer verified"), which unlocks selling.
/// </summary>
public class FarmerProfile : Entity
{
    public Guid UserId { get; set; }
    public string? Village { get; set; }
    public string? Mandal { get; set; }
    public string? District { get; set; }
    /// <summary>Approximate, optional.</summary>
    public decimal? FarmSizeAcres { get; set; }
    public ProduceSource? ProduceSource { get; set; }
    public EvidenceType? EvidenceType { get; set; }
    /// <summary>Farmer ID number, FPO name, or the referee's name and phone — whatever fits the evidence type.</summary>
    public string? EvidenceDetails { get; set; }
    public VerificationStatus Status { get; set; } = VerificationStatus.NotStarted;
    public int Level { get; set; }
    public string? RejectionReason { get; set; }
    public DateTime? SubmittedAt { get; set; }
    /// <summary>The verifier (a user with the Verifier role) who reviews this farmer.</summary>
    public Guid? AssignedVerifierId { get; set; }
    public DateTime? AssignedAt { get; set; }
    public DateTime? ReviewedAt { get; set; }
    public Guid? ReviewedBy { get; set; }
    public List<FarmerCrop> Crops { get; set; } = [];
    /// <summary>Survey-number plots, kept for the later automated land-record check. The MVP flow does not collect them.</summary>
    public List<FarmPlot> Plots { get; set; } = [];

    public bool CanEdit => Status is VerificationStatus.NotStarted or VerificationStatus.Rejected;

    /// <summary>The evidence photo can still be replaced or deleted while waiting for review, but not once verified.</summary>
    public bool CanChangeDocuments => Status is not VerificationStatus.Verified;
}

public class FarmerCrop : Entity
{
    public Guid FarmerId { get; set; }
    public required string CropCode { get; set; }
}

public class FarmPlot : Entity
{
    public Guid FarmerId { get; set; }
    public required string SurveyNumber { get; set; }
    public decimal ExtentAcres { get; set; }
    public OwnershipType OwnershipType { get; set; }
    /// <summary>Point captured while the farmer stands on the farm (SRID 4326).</summary>
    public Point? Location { get; set; }
    public List<PlotCrop> Crops { get; set; } = [];
}

public class PlotCrop : Entity
{
    public Guid PlotId { get; set; }
    public required string CropCode { get; set; }
}

/// <summary>Evidence is the MVP flow's only photo; the other types belong to the earlier Aadhaar + land flow.</summary>
public enum DocumentType { AadhaarCard, Selfie, LandProof, FarmPhoto, Evidence }

/// <summary>A private KYC/land file. Visible only to its owner and verifiers.</summary>
public class VerificationDocument : Entity
{
    public Guid OwnerUserId { get; set; }
    public DocumentType Type { get; set; }
    public required string FilePath { get; set; }
    public required string ContentType { get; set; }
    public Point? CapturedAt { get; set; }
}
