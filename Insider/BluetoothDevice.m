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
        _log_a = @(-39.89);
        _log_b = @(-12.16);
        _tanh_a = @(-0.633);
        _tanh_b = @(0.199);
        _deviceRSSI = rssi;
        _distance = @([self rssi2distance:_deviceRSSI.floatValue]);
        _abandonDist = @([self rssi2abandonDist:_deviceRSSI.floatValue]);
        _historyData = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (float)operateKalmanFilterWithObservation:(float)observation {
    float filterResult = [_kalmanFilter filterWithObservation:observation];
    _distance = @([self rssi2distance:filterResult]);
    _abandonDist = @([self rssi2abandonDist:filterResult]);
    return _distance.floatValue;
}

- (float)rssi2distance:(float)rssi {
    return (pow(10, (rssi - self.log_a.floatValue) / self.log_b.floatValue) / 100.0 * 0.225 +
            tanhf((rssi + 60.0) / 30.0 * _tanh_a.floatValue + _tanh_b.floatValue) * 10 * 0.775);
}

- (float)rssi2abandonDist:(float)rssi {
    return (pow(10, (rssi - self.log_a.floatValue) / self.log_b.floatValue) / 100.0);
}

@end
