# Third-party DLLs

| File | What | Source |
|---|---|---|
| `Kinichit.Communication.dll` (+ `.xml` for IntelliSense) | Email and SMS sending, plus the SQL Server email queue | [SantoshRamancha/CommunicationProvider](https://github.com/SantoshRamancha/CommunicationProvider), tag `v1.1.0`, built in Release |

Referenced from `src/AanganMandi.Infrastructure/AanganMandi.Infrastructure.csproj`. A DLL brings none of its own
dependencies, so that project also lists the packages the library was built against (`Microsoft.Data.SqlClient` 6.1.6,
`Microsoft.Extensions.Http`, `…Hosting.Abstractions`, `…Logging.Abstractions`, `…Options.ConfigurationExtensions`).

## Updating to a newer version

```bash
git clone --branch v<version> https://github.com/SantoshRamancha/CommunicationProvider.git
dotnet build CommunicationProvider/src/Kinichit.Communication/Kinichit.Communication.csproj -c Release -p:Version=<version>
```

Copy `Kinichit.Communication.dll` and `Kinichit.Communication.xml` from `bin/Release/net8.0/` over the files here, compare the
`<PackageReference>`s in the library's `.csproj` with the list above, and update this table.
