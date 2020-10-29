//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

public enum DataSourceFetchState<Failure: Error> {
	case fetching
	case finished
	case failure(_ error: Failure)
}
