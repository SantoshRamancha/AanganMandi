using AanganMandi.Infrastructure;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using AanganMandi.Application.Storage;
using StorageProvider;

namespace AanganMandi.Tests;

public class FileStorageTests
{
    /// <summary>An in-memory bucket with the same rules as the real one (keys checked, missing → null).</summary>
    private sealed class FakeBucket : IStorageProvider
    {
        public readonly Dictionary<string, (byte[] Bytes, string ContentType)> Objects = [];

        public async Task<StoredObject> UploadAsync(string key, Stream content, string contentType, CancellationToken ct = default)
        {
            StorageKey.Validate(key);
            using var copy = new MemoryStream();
            await content.CopyToAsync(copy, ct);
            Objects[key] = (copy.ToArray(), contentType);
            return new StoredObject(key, copy.Length, null, DateTimeOffset.UtcNow);
        }

        public Task<StorageDownload?> DownloadAsync(string key, CancellationToken ct = default) =>
            Task.FromResult(Objects.TryGetValue(key, out var o)
                ? new StorageDownload(new MemoryStream(o.Bytes), key, o.ContentType, o.Bytes.Length, null, null)
                : null);

        public Task<bool> ExistsAsync(string key, CancellationToken ct = default) => Task.FromResult(Objects.ContainsKey(key));

        public Task DeleteAsync(string key, CancellationToken ct = default)
        {
            Objects.Remove(key);
            return Task.CompletedTask;
        }

        public Task<IReadOnlyList<StoredObject>> ListAsync(string folder, CancellationToken ct = default) => throw new NotSupportedException();
        public string GetPresignedDownloadUrl(string key, TimeSpan validFor) => throw new NotSupportedException();
    }

    private static async Task<byte[]> ReadAll(Stream s)
    {
        await using (s)
        {
            using var copy = new MemoryStream();
            await s.CopyToAsync(copy);
            return copy.ToArray();
        }
    }

    [Fact]
    public async Task Bucket_storage_saves_under_the_prefix_and_returns_the_plain_relative_path()
    {
        var bucket = new FakeBucket();
        var storage = new ObjectFileStorage(bucket, "dev");

        var path = await storage.SaveAsync(new MemoryStream([1, 2, 3]), "spaces/abc", ".png");

        Assert.Matches(@"^spaces/abc/[0-9a-f]{32}\.png$", path);
        var (bytes, type) = Assert.Single(bucket.Objects, o => o.Key == $"dev/{path}").Value;
        Assert.Equal([1, 2, 3], bytes);
        Assert.Equal("image/png", type);
        Assert.Equal([1, 2, 3], await ReadAll((await storage.OpenReadAsync(path))!));
    }

    [Fact]
    public async Task Bucket_storage_deletes_and_reports_missing_files_as_null()
    {
        var bucket = new FakeBucket();
        var storage = new ObjectFileStorage(bucket, null);
        var path = await storage.SaveAsync(new MemoryStream([9]), "kyc/user1", ".jpg");
        Assert.True(bucket.Objects.ContainsKey(path)); // no prefix: the key is the path itself

        await storage.DeleteAsync(path);
        Assert.Empty(bucket.Objects);
        Assert.Null(await storage.OpenReadAsync(path));
        await storage.DeleteAsync(path); // deleting again is not an error
    }

    [Theory]
    [InlineData("../kyc/other/file.jpg")]
    [InlineData("spaces/../../kyc/x.jpg")]
    [InlineData("/spaces/x.jpg")]
    [InlineData(@"spaces\x.jpg")]
    public async Task Bucket_storage_refuses_paths_that_escape_their_folder(string path)
    {
        var storage = new ObjectFileStorage(new FakeBucket(), "dev");
        await Assert.ThrowsAsync<ArgumentException>(() => storage.OpenReadAsync(path));
    }

    [Fact]
    public async Task Local_storage_round_trips_and_refuses_paths_outside_its_root()
    {
        var root = Path.Combine(Path.GetTempPath(), $"am-storage-{Guid.NewGuid():N}");
        try
        {
            var storage = new LocalFileStorage(root);
            var path = await storage.SaveAsync(new MemoryStream([4, 5]), "spaces/s1", ".webp");
            Assert.Equal([4, 5], await ReadAll((await storage.OpenReadAsync(path))!));
            await storage.DeleteAsync(path);
            Assert.Null(await storage.OpenReadAsync(path));
            await Assert.ThrowsAsync<UnauthorizedAccessException>(() => storage.OpenReadAsync("../outside.jpg"));
            await Assert.ThrowsAsync<UnauthorizedAccessException>(() => storage.OpenReadAsync($"../{Path.GetFileName(root)}x/a.jpg"));
        }
        finally
        {
            if (Directory.Exists(root)) Directory.Delete(root, recursive: true);
        }
    }

    [Theory]
    [InlineData("Object", typeof(ObjectFileStorage))]
    [InlineData("object", typeof(ObjectFileStorage))]
    [InlineData("Local", typeof(LocalFileStorage))]
    [InlineData(null, typeof(LocalFileStorage))]
    public void Storage_provider_setting_picks_the_storage(string? provider, Type expected)
    {
        var config = new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?>
        {
            ["Storage:Provider"] = provider,
            ["StorageProvider:ServiceUrl"] = "https://objectstore.example.test",
            ["StorageProvider:BucketName"] = "aangan-mandi",
            ["StorageProvider:AccessKey"] = "test-access",
            ["StorageProvider:SecretKey"] = "test-secret",
            ["ConnectionStrings:Default"] = "Server=none;Database=none",
            ["EmailQueue:ConnectionStringName"] = "Default",
        }).Build();
        using var services = new ServiceCollection().AddLogging().AddInfrastructure(config, Path.GetTempPath()).BuildServiceProvider();
        Assert.IsType(expected, services.GetRequiredService<IFileStorage>());
    }

    [Fact]
    public void Bucket_storage_without_keys_fails_naming_each_missing_setting()
    {
        var config = new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?>
        {
            ["Storage:Provider"] = "Object",
            ["ConnectionStrings:Default"] = "Server=none;Database=none",
            ["EmailQueue:ConnectionStringName"] = "Default",
        }).Build();
        using var services = new ServiceCollection().AddLogging().AddInfrastructure(config, Path.GetTempPath()).BuildServiceProvider();
        var error = Assert.Throws<InvalidOperationException>(() => services.GetRequiredService<IFileStorage>());
        Assert.Contains("StorageProvider:AccessKey", error.Message);
        Assert.Contains("StorageProvider:SecretKey", error.Message);
    }
}
