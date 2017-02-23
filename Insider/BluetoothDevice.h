//
//  BluetoothDevice.h
//  Insider
//
//  Created by Lun on 2017/1/17.
//  Copyright © 2017年 Lun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KalmanFilter.h"
#import "ParticleFilter.h"

@interface BluetoothDevice : NSObject

@property (strong, nonatomic) NSString *deviceUUID;
@property (retain, nonatomic) NSNumber *x;
@property (retain, nonatomic) NSNumber *y;
@property (retain, nonatomic) NSNumber *distance;
@property (retain, nonatomic) NSNumber *deviceRSSI;
@property (strong, nonatomic) NSMutableArray *historyData;
@property (strong, nonatomic) KalmanFilter *kalmanFilter;

- (BluetoothDevice *)initWithUUID:(NSString *)uuid RSSI:(NSNumber *)rssi;
- (float)operateKalmanFilterWithObservation:(float)observation;
+ (float)rssi2distance:(float)rssi;
+ (float)distance2rssi:(float)dist;

@end
