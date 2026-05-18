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
    baseURL: URL(string: "https://research.example.com")!,
    apiKey: "..."
)

let studyUploader = StudyDataUploader(client: studyClient)
let studyFileManager = StudyFileManager(uploader: studyUploader)
let enrollmentService = RemoteEnrollmentService(client: studyClient)
```

Pass `studyFileManager` into a `Study` initializer when automatic `uploadIfNecessary()` calls should use that injected uploader.

`UploadConfiguration` is kept for legacy upload-frequency configuration:

```swift
UploadConfiguration(
    serverURL: URL(string: "https://research.example.com")!,
    uploadFrequency: 60 * 60 * 24,
    apiKey: "..."
)
```

The generated OpenAPI client sends the API key as the `X-API-Key` header. Local files that are ready for upload are staged in timestamped batches under `OpenResearchKit/Studies/<study>/upload/yyyyMMdd_HHmmss/`. A successful upload removes each uploaded local file and then marks the study upload as successful after the whole batch sweep completes.

### Optional live upload integration tests

Upload integration tests run offline by default. To test uploads against the live study API, provide the private API key and server-side study identifier through the environment:

```sh
OPENRESEARCHKIT_RUN_LIVE_UPLOAD_TESTS=1 \
OPENRESEARCHKIT_STUDY_API_KEY='<private-key>' \
OPENRESEARCHKIT_LIVE_UPLOAD_STUDY_IDENTIFIER='<server-study-id>' \
xcodebuild test -scheme OpenResearchKit -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.4' -only-testing:OpenResearchKitTests/StudyDataUploaderLiveIntegrationTests
```

`OPENRESEARCHKIT_STUDY_API_BASE_URL` can be set to override the default `https://study.one-sec.app` endpoint. When the run flag or required credentials are missing, the live integration test is skipped.

![openresearchkit](https://user-images.githubusercontent.com/5204169/202870439-0d5b541c-2ffb-4eff-a138-d2eaaa84cfa6.png)
