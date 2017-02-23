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
        _distance = @([BluetoothDevice rssi2distance:_deviceRSSI.floatValue]);
        _historyData = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (float)operateKalmanFilterWithObservation:(float)observation {
    float filterResult = [_kalmanFilter filterWithObservation:observation];
    _distance = @([BluetoothDevice rssi2distance:filterResult]);
    return _distance.floatValue;
}

+ (float)rssi2distance:(float)rssi {
    return pow(10, (rssi - val_a) / val_b);
}

+ (float)distance2rssi:(float)dist {
    return val_a + val_b * log10(dist);
}

@end
