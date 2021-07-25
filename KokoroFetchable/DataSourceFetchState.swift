//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

public enum DataSourceFetchState<Failure: Error> {
	case fetching
	case success
	case failure(_ error: Failure)

	public func mapError<NewFailure>(_ mapper: (Failure) -> NewFailure) -> DataSourceFetchState<NewFailure> {
		switch self {
		case let .failure(error):
			return .failure(mapper(error))
		case .fetching:
			return .fetching
		case .success:
			return .success
		}
	}
}
