# Third-party DLLs

| File | What | Source |
|---|---|---|
| `Kinichit.Communication.dll` (+ `.xml` for IntelliSense) | Email and SMS sending, plus the SQL Server email queue | [SantoshRamancha/CommunicationProvider](https://github.com/SantoshRamancha/CommunicationProvider), tag `v1.1.0`, built in Release |
| `StorageProvider/StorageProvider.dll` (+ `.xml`) | Uploaded files in the product's E2E Object Storage (S3-compatible) bucket | [SantoshRamancha/StorageProvider](https://github.com/SantoshRamancha/StorageProvider), commit `bfa9201` (1.0.0, no tag yet), built in Release |

Both are referenced from `src/AanganMandi.Infrastructure/AanganMandi.Infrastructure.csproj` (StorageProvider also from
the test project). A DLL brings none of its own dependencies, so that project also lists the packages each library was
built against: for Kinichit.Communication `Microsoft.Data.SqlClient` 6.1.6, `Microsoft.Extensions.Http`,
`…Hosting.Abstractions`, `…Logging.Abstractions`, `…Options.ConfigurationExtensions`; for StorageProvider `AWSSDK.S3`
4.0.104.7.

## Updating to a newer version

```bash
git clone --branch v<version> https://github.com/SantoshRamancha/CommunicationProvider.git
dotnet build CommunicationProvider/src/Kinichit.Communication/Kinichit.Communication.csproj -c Release -p:Version=<version>
```

Copy `Kinichit.Communication.dll` and `Kinichit.Communication.xml` from `bin/Release/net8.0/` over the files here, compare the
`<PackageReference>`s in the library's `.csproj` with the list above, and update this table.
