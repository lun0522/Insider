//
//  ModelViewController.h
//  Insider
//
//  Created by Lun on 2017/1/19.
//  Copyright © 2017年 Lun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreMotion/CoreMotion.h>
#import <CoreLocation/CoreLocation.h>
#import <AVOSCloud/AVOSCloud.h>
#import <mach/mach_time.h>
#import "BluetoothDevice.h"
#import "PNChart.h"

#define CHART_CAPACITY         80
#define CHART_INIT_VALUE    -60.0

typedef NS_ENUM(NSInteger, StopReason) {
    bluetoothShutDown,
    uploadFailed,
    filterFailed,
    accomplished,
    shouldChange,
    cancelled
};

@interface ModelViewController : UIViewController <CBCentralManagerDelegate,UITextFieldDelegate,UITableViewDelegate,UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *deviceList;
@property (weak, nonatomic) IBOutlet UITableView *rssiList;
@property (weak, nonatomic) IBOutlet UITextField *sampleSize;
@property (weak, nonatomic) IBOutlet UITextField *beaconName;
@property (weak, nonatomic) IBOutlet UITextField *headingText;
@property (weak, nonatomic) IBOutlet UITextField *pitchText;
@property (weak, nonatomic) IBOutlet UILabel *sizeIndicator;
@property (weak, nonatomic) IBOutlet UILabel *DAIndicator;
@property (weak, nonatomic) IBOutlet UIView *chartView;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet UIButton *neuralButton;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UITextField *distX;
@property (weak, nonatomic) IBOutlet UITextField *distY;
@property (weak, nonatomic) IBOutlet UIImageView *eulerView;
@property (strong, nonatomic) NSMutableArray *devicesUUID;
@property (strong, nonatomic) NSMutableArray *devicesInfo;
@property (strong, nonatomic) NSMutableArray *sampledUUID;
@property (strong, nonatomic) NSMutableArray *rawData;
@property (strong, nonatomic) NSMutableArray *KalmanData;
@property (assign, nonatomic) uint64_t startTime;
@property (assign, nonatomic) float kalman_Q;
@property (assign, nonatomic) float kalman_R;
@property (assign, nonatomic) BOOL isDistance;
@property (assign, nonatomic) BOOL isSampling;
@property (assign, nonatomic) BOOL isNeural;
@property (assign, nonatomic) BOOL isCharting;

@property (strong, nonatomic) CBCentralManager *bluetoothManager;
@property (strong, nonatomic) BluetoothDevice *beingSampledBeacon;
@property (strong, nonatomic) CMMotionManager *motionManager;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (retain, nonatomic) NSTimer *scanTimer;
@property (retain, nonatomic) NSTimer *renewTimer;
@property (retain, nonatomic) UIVisualEffectView *blurEffect;
@property (retain, nonatomic) UITextField *samplingText;
@property (retain, nonatomic) UIActivityIndicatorView *samplingIndicator;
@property (retain, nonatomic) UIProgressView *samplingProgress;
@property (retain, nonatomic) UIButton *cancelButton;
@property (strong, nonatomic) PNLineChart *lineChart;

@end
