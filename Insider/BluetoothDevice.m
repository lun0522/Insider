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
        _x = @(0.0);
        _y = @(0.0);
        _roll  = @(0.0);
        _pitch = @(0.0);
        _yaw   = @(0.0);
        _a = @(0.0);
        _b = @(0.0);
        _deviceRSSI = rssi;
        _distance = @([self rssi2distance:_deviceRSSI.floatValue]);
        _historyData = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (float)operateKalmanFilterWithObservation:(float)observation {
    float filterResult = [_kalmanFilter filterWithObservation:observation];
    _distance = @([self rssi2distance:filterResult]);
    return _distance.floatValue;
}

- (float)rssi2distance:(float)rssi {
    return pow(10, (rssi - self.a.floatValue) / self.b.floatValue);
}

- (float)distance2rssi:(float)dist {
    return self.a.floatValue + self.b.floatValue * log10(dist);
}

@end
