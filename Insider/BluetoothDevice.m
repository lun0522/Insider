//
//  BluetoothDevice.m
//  Insider
//
//  Created by Lun on 2017/1/17.
//  Copyright © 2017年 Lun. All rights reserved.
//

#import "BluetoothDevice.h"

@implementation BluetoothDevice

- (BluetoothDevice *)initWithUUID:(NSString *)uuid RSSI:(NSNumber *)rssi {
    if (self = [super init]) {
        _deviceUUID = uuid;
        _x = @(-1);
        _y = @(-1);
        _deviceRSSI = rssi;
        _distance = [NSNumber numberWithFloat:pow(10, (_deviceRSSI.floatValue - val_a) / val_b)];
        _historyData = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (float)operateKalmanFilterWithObservation:(float)observation {
    float filterResult = [_kalmanFilter filterWithObservation:observation];
    _distance = @(pow(10, (filterResult - val_a) / val_b));
    return _distance.floatValue;
}

- (float)operateParticleFilterWithObservation:(float)observation {
    float filterResult = [_particleFilter filterWithObservation:observation];
    _distance = @(pow(10, (filterResult - val_a) / val_b));
    return _distance.floatValue;
}

@end
