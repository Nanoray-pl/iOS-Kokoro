//
//  Created on 04/12/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

public enum Fetchable<T, Failure: Error> {
	case fetching
	case success(_ data: T)
	case failure(_ error: Failure)

	public func map<NewT>(_ mapper: (T) -> NewT) -> Fetchable<NewT, Failure> {
		switch self {
		case let .success(data):
			return .success(mapper(data))
		case let .failure(error):
			return .failure(error)
		case .fetching:
			return .fetching
		}
	}

	public func mapError<NewFailure>(_ mapper: (Failure) -> NewFailure) -> Fetchable<T, NewFailure> {
		switch self {
		case let .success(data):
			return .success(data)
		case let .failure(error):
			return .failure(mapper(error))
		case .fetching:
			return .fetching
		}
	}

	public func data(orDefaultValue defaultValue: @autoclosure () -> T) -> T {
		switch self {
		case let .success(data):
			return data
		case .failure, .fetching:
			return defaultValue()
		}
	}

	public func optionalData() -> T? {
		switch self {
		case let .success(data):
			return data
		case .failure, .fetching:
			return nil
		}
	}

	public var fetchState: DataSourceFetchState<Failure> {
		switch self {
		case .fetching:
			return .fetching
		case .success:
			return .success
		case let .failure(error):
			return DataSourceFetchState<Failure>.failure(error)
		}
	}
}

#if canImport(Combine)
import Combine

public extension Publisher {
	func mapFetchable() -> AnyPublisher<Fetchable<Output, Failure>, Never> {
		return map { .success($0) }
			.catch { Just(.failure($0)) }
			.eraseToAnyPublisher()
	}
}
#endif
