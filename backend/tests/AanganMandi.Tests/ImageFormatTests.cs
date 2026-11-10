using AanganMandi.Application.Files;

namespace AanganMandi.Tests;

public class ImageFormatTests
{
    private static readonly byte[] JpegHead = [0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01];
    private static readonly byte[] PngHead = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D];
    private static readonly byte[] WebpHead = [.."RIFF"u8, 0x24, 0x00, 0x00, 0x00, .."WEBP"u8];
    private static readonly byte[] AvifHead = [0x00, 0x00, 0x00, 0x1C, .."ftypavif"u8];
    private static readonly byte[] HeicHead = [0x00, 0x00, 0x00, 0x18, .."ftypheic"u8];
    private static readonly byte[] GifHead = [.."GIF89a"u8, 0x01, 0x00, 0x01, 0x00, 0x80, 0x00];
    private static readonly byte[] PdfHead = [.."%PDF-1.7\n%"u8, 0xE2, 0xE3];

    [Fact]
    public void Jpeg_png_and_webp_are_recognised_from_their_bytes()
    {
        Assert.Same(ImageFormat.Jpeg, ImageFormat.Detect(JpegHead));
        Assert.Same(ImageFormat.Png, ImageFormat.Detect(PngHead));
        Assert.Same(ImageFormat.Webp, ImageFormat.Detect(WebpHead));
    }

    [Fact]
    public void Other_formats_and_short_files_are_refused()
    {
        Assert.Null(ImageFormat.Detect(AvifHead));
        Assert.Null(ImageFormat.Detect(HeicHead));
        Assert.Null(ImageFormat.Detect(GifHead));
        Assert.Null(ImageFormat.Detect(PdfHead));
        Assert.Null(ImageFormat.Detect([]));
        Assert.Null(ImageFormat.Detect([0xFF, 0xD8]));
        Assert.Null(ImageFormat.Detect("RIFF"u8));
    }

    [Fact]
    public async Task Detection_reads_only_the_start_of_a_stream()
    {
        // A PNG the web picker produced from an AVIF: the bytes decide, whatever label came with it.
        using var stream = new MemoryStream([.. PngHead, .. new byte[5000]]);
        Assert.Same(ImageFormat.Png, await ImageFormat.DetectAsync(stream));
        Assert.Equal(ImageFormat.HeaderLength, stream.Position);
    }

    [Fact]
    public void Each_format_has_a_matching_file_extension()
    {
        Assert.Equal((".jpg", "image/jpeg"), (ImageFormat.Jpeg.Extension, ImageFormat.Jpeg.ContentType));
        Assert.Equal((".png", "image/png"), (ImageFormat.Png.Extension, ImageFormat.Png.ContentType));
        Assert.Equal((".webp", "image/webp"), (ImageFormat.Webp.Extension, ImageFormat.Webp.ContentType));
    }
}
