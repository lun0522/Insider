//
//  Trilateration.h
//  Insider
//
//  Created by Lun on 2017/2/12.
//  Copyright © 2017年 Lun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BluetoothDevice.h"

@interface Trilateration : NSObject

+ (NSArray *)trilaterateWithBeacons:(NSMutableArray *)beacons;

@end
