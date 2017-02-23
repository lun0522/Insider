//
//  PositionViewController.h
//  Insider
//
//  Created by Lun on 2017/1/25.
//  Copyright © 2017年 Lun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <AVOSCloud/AVOSCloud.h>
#import "BluetoothDevice.h"
#import "Trilateration.h"

#define enableTracking        1

@interface PositionViewController : UIViewController <CBCentralManagerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *beaconOne;
@property (weak, nonatomic) IBOutlet UILabel *beaconTwo;
@property (weak, nonatomic) IBOutlet UILabel *beaconThree;
@property (weak, nonatomic) IBOutlet UIImageView *map;
@property (weak, nonatomic) IBOutlet UIImageView *topLayer;
@property (weak, nonatomic) IBOutlet UIButton *backButton;

@property (strong, nonatomic) NSMutableArray *beaconsList;
@property (strong, nonatomic) NSMutableArray *beaconsUUID;
@property (assign, nonatomic) float kalman_Q;
@property (assign, nonatomic) float kalman_R;
@property (assign, nonatomic) float particle_Q;
@property (assign, nonatomic) float particle_R;

@property (strong, nonatomic) CBCentralManager *bluetoothManager;
@property (retain, nonatomic) NSTimer *timer;
@property (strong, nonatomic) UIButton *dot;
@property (strong, nonatomic) ParticleFilter *particleFilter;

@end
