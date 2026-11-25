import XCTest
@testable import FieldBriefCore

final class InferencePolicyTests: XCTestCase {
    func testLocalOnlyWhenAvailableAndNoConsent() {
        XCTAssertEqual(InferencePolicy.mode(localAvailable: true, cloudConsented: false), .onDeviceOnly)
    }

    func testBlocksWhenLocalUnavailableAndNoConsent() {
        XCTAssertEqual(InferencePolicy.mode(localAvailable: false, cloudConsented: false), .blocked)
    }

    func testHybridRequiresPositiveCloudConsent() {
        XCTAssertEqual(InferencePolicy.mode(localAvailable: true, cloudConsented: true), .hybridWithCloudConsent)
        XCTAssertEqual(InferencePolicy.mode(localAvailable: false, cloudConsented: true), .hybridWithCloudConsent)
    }

    func testReportsAppleLocalInference() {
        XCTAssertEqual(InferenceRoute.reported(modelVersion: "apple-foundation-models-system-language-model"), .onDevice)
    }

    func testReportsCloudModelName() {
        XCTAssertEqual(InferenceRoute.reported(modelVersion: "gemini-3.5-flash-lite"), .cloud(model: "gemini-3.5-flash-lite"))
    }

    func testDoesNotMislabelUnknownAsCloud() {
        XCTAssertEqual(InferenceRoute.reported(modelVersion: "unknown-model-version"), .unknown)
    }
}
