//
//  Created on 01/03/2021.
//  Copyright © 2021 Ordnance Survey. All rights reserved.
//

import Combine
import XCTest
@testable import KokoroFetchable

class PublisherListDataSourceTests: XCTestCase {
    func testPublisher() {
        enum Error: Swift.Error {
            case error
        }

        var subject: PassthroughSubject<(elements: [Int], isLast: Bool), Swift.Error>!
        var fetchAdditionalDataResult: Bool!
        let testedDataSource = PublisherListDataSource<Int> { _ -> PassthroughSubject<(elements: [Int], isLast: Bool), Swift.Error> in
            subject = PassthroughSubject()
            return subject
        }

        XCTAssertEqual(testedDataSource.isFetching, false)
        XCTAssertNil(testedDataSource.error)
        XCTAssertEqual(testedDataSource.count, 0)
        XCTAssertEqual(testedDataSource.elements, [])

        fetchAdditionalDataResult = testedDataSource.fetchAdditionalData()
        XCTAssertEqual(fetchAdditionalDataResult, true)

        subject.send(completion: .failure(Error.error))

        XCTAssertEqual(testedDataSource.isFetching, false)
        XCTAssertEqual(testedDataSource.count, 0)
        XCTAssertEqual(testedDataSource.elements, [])

        switch testedDataSource.error {
        case .some(Error.error):
            break
        default:
            XCTFail("Expected \(Error.error), got \(String(describing: testedDataSource.error)) instead")
        }

        fetchAdditionalDataResult = testedDataSource.fetchAdditionalData()
        XCTAssertEqual(fetchAdditionalDataResult, true)

        XCTAssertEqual(testedDataSource.isFetching, true)
        XCTAssertNil(testedDataSource.error)
        XCTAssertEqual(testedDataSource.count, 0)
        XCTAssertEqual(testedDataSource.elements, [])

        subject.send((elements: [1, 2, 3], isLast: false))
        subject.send(completion: .finished)

        XCTAssertEqual(testedDataSource.isFetching, false)
        XCTAssertNil(testedDataSource.error)
        XCTAssertEqual(testedDataSource.count, 3)
        XCTAssertEqual(testedDataSource.elements, [1, 2, 3])

        fetchAdditionalDataResult = testedDataSource.fetchAdditionalData()
        XCTAssertEqual(fetchAdditionalDataResult, true)

        subject.send((elements: [1, 2, 3], isLast: true))
        subject.send(completion: .finished)

        XCTAssertEqual(testedDataSource.isFetching, false)
        XCTAssertNil(testedDataSource.error)
        XCTAssertEqual(testedDataSource.count, 6)
        XCTAssertEqual(testedDataSource.elements, [1, 2, 3, 1, 2, 3])

        fetchAdditionalDataResult = testedDataSource.fetchAdditionalData()
        XCTAssertEqual(fetchAdditionalDataResult, false)

        XCTAssertEqual(testedDataSource.isFetching, false)
        XCTAssertNil(testedDataSource.error)
        XCTAssertEqual(testedDataSource.count, 6)
        XCTAssertEqual(testedDataSource.elements, [1, 2, 3, 1, 2, 3])

        testedDataSource.reset()

        XCTAssertEqual(testedDataSource.isFetching, false)
        XCTAssertNil(testedDataSource.error)
        XCTAssertEqual(testedDataSource.count, 0)
        XCTAssertEqual(testedDataSource.elements, [])
    }
}
