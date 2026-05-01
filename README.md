# OpenResearchKit-Swift

A Swift Package to conduct scientific research in iPhone apps:
- Invite users to participate
- Get user consent
- Surveys
- Collect study data
- Combine survey replies and study data anonymously

## Study Data Uploads

OpenResearchKit uploads study data through a v2 study API. Create the generated OpenAPI `Client` in the host app and pass it into the upload and enrollment services:

```swift
let studyClient = Client(
    studyAPIBaseURL: URL(string: "https://research.example.com")!,
    apiKey: "..."
)

let studyFileManager = StudyFileManager(client: studyClient)
let studyUploader = StudyDataUploader(client: studyClient)
let enrollmentService = RemoteEnrollmentService(client: studyClient)
```

Pass `studyFileManager` into a `Study` initializer when automatic `uploadIfNecessary()` calls should use that injected uploader.

`UploadConfiguration` is kept for legacy upload-frequency configuration:

```swift
UploadConfiguration(uploadFrequency: 60 * 60 * 24)
```

The generated OpenAPI client sends the API key as the `X-API-Key` header. Local files that are ready for upload are staged in timestamped batches under `OpenResearchKit/Studies/<study>/upload/yyyyMMdd_HHmmss/`. A successful upload removes each uploaded local file and then marks the study upload as successful after the whole batch sweep completes.

![openresearchkit](https://user-images.githubusercontent.com/5204169/202870439-0d5b541c-2ffb-4eff-a138-d2eaaa84cfa6.png)
