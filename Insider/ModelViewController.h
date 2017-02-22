//
//  ModelViewController.h
//  Insider
//
//  Created by Lun on 2017/1/19.
//  Copyright © 2017年 Lun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <AVOSCloud/AVOSCloud.h>
#import "BluetoothDevice.h"
#import "PNChart.h"

#define CHART_CAPACITY         80
#define CHART_INIT_VALUE    -30.0

typedef NS_ENUM(NSInteger, StopReason) {
    bluetoothShutDown,
    uploadFailed,
    filterFailed,
    accomplished
};

@interface ModelViewController : UIViewController <CBCentralManagerDelegate,UITextFieldDelegate,UITableViewDelegate,UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITextField *bluetoothState;
@property (weak, nonatomic) IBOutlet UITableView *deviceList;
@property (weak, nonatomic) IBOutlet UITableView *rssiList;
@property (weak, nonatomic) IBOutlet UITextField *sampleSize;
@property (weak, nonatomic) IBOutlet UITextField *beaconName;
@property (weak, nonatomic) IBOutlet UITextField *distORang;
@property (weak, nonatomic) IBOutlet UILabel *sizeIndicator;
@property (weak, nonatomic) IBOutlet UILabel *DAIndicator;
@property (weak, nonatomic) IBOutlet UIView *chartView;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet UIButton *backButton;

@property (strong, nonatomic) NSMutableArray *devicesUUID;
@property (strong, nonatomic) NSMutableArray *devicesInfo;
@property (strong, nonatomic) NSMutableArray *sampledUUID;
@property (strong, nonatomic) NSMutableArray *rawData;
@property (strong, nonatomic) NSMutableArray *KalmanData;
@property (strong, nonatomic) NSMutableArray *ParticleData;
@property (assign, nonatomic) float kalman_Q;
@property (assign, nonatomic) float kalman_R;
@property (assign, nonatomic) float particle_Q;
@property (assign, nonatomic) float particle_R;
@property (assign, nonatomic) BOOL isDistance;
@property (assign, nonatomic) BOOL isSampling;
@property (assign, nonatomic) BOOL isCharting;

@property (strong, nonatomic) CBCentralManager *bluetoothManager;
@property (strong, nonatomic) BluetoothDevice *beingSampledBeacon;
@property (retain, nonatomic) NSTimer *timer;
@property (retain, nonatomic) UIVisualEffectView *blurEffect;
@property (retain, nonatomic) UITextField *samplingText;
@property (retain, nonatomic) UIActivityIndicatorView *samplingIndicator;
@property (retain, nonatomic) UIProgressView *samplingProgress;
@property (strong, nonatomic) PNLineChart *lineChart;

@end
