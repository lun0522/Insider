//
//  PositionViewController.m
//  Insider
//
//  Created by Lun on 2017/1/25.
//  Copyright © 2017年 Lun. All rights reserved.
//

#import "PositionViewController.h"

@interface PositionViewController () {
    float lastX;
    float lastY;
    float lastAbandonX;
    float lastAbandonY;
    CAShapeLayer *circle1;
    CAShapeLayer *circle2;
    CAShapeLayer *circle3;
}

@end

@implementation PositionViewController

#pragma mark - Lifecycle Methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
    lastX = -1;
    lastY = -1;
    lastAbandonX = -1;
    lastAbandonY = -1;
    [self initArray];
    [self initButton];
    [self initBluetooth];
    [self initTimer];
    [self initDot];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self stopScanning];
    [self.timer invalidate];
    self.timer = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Initialazation

- (void)initArray {
    self.beaconsList = [[NSMutableArray alloc] init];
    self.beaconsUUID = [[NSMutableArray alloc] init];
}

- (void)initButton {
    [self.backButton addTarget:self
                        action:@selector(dismiss)
              forControlEvents:UIControlEventTouchUpInside];
}

- (void)initBluetooth {
    self.bluetoothManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

- (void)initTimer {
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 / DEFAULT_FREQUENCY
                                                  target:self
                                                selector:@selector(startScanning)
                                                userInfo:nil
                                                 repeats:YES];
    [self.timer setFireDate:[NSDate distantFuture]];
}

- (void)initDot {
    self.dot = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.dot setImage:[UIImage imageNamed:@"dot.png"] forState:UIControlStateNormal];
    self.dot.frame = CGRectMake(0, 0, 20, 20);
    [self.topLayer addSubview:self.dot];
}

#pragma mark - Bluetooth

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state == CBManagerStatePoweredOn) {
        [self.timer setFireDate:[NSDate distantPast]];
    } else {
        [self stopScanning];
        [self.timer setFireDate:[NSDate distantFuture]];
    }
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary<NSString *,id> *)advertisementData
                  RSSI:(NSNumber *)RSSI {
    if (RSSI.intValue <= RSSI_MAXIMUM && RSSI.intValue >= RSSI_MINIMUM) {
        NSString *uuidString = peripheral.identifier.UUIDString;
        
        if ([uuidString isEqualToString:UUID5] || [uuidString isEqualToString:UUID6] || [uuidString isEqualToString:UUID7]) {
            if (![self.beaconsUUID containsObject:uuidString]) {
                [self.beaconsUUID addObject:uuidString];
                
                BluetoothDevice *beacon = [[BluetoothDevice alloc] initWithUUID:uuidString
                                                                           RSSI:RSSI];

                beacon.kalmanFilter = [[KalmanFilter alloc] initWithQ:self.kalman_Q
                                                                    R:self.kalman_R
                                                                   X0:RSSI.floatValue
                                                                   P0:DEFAULT_P0];
                [beacon operateKalmanFilterWithObservation:RSSI.floatValue];
                
                [self.beaconsList addObject:beacon];
                
                [self displayDistance:beacon.distance onIndex:[self.beaconsUUID count]];
            } else {
                NSInteger index = [self.beaconsUUID indexOfObject:uuidString];
                
                BluetoothDevice *beacon = [self.beaconsList objectAtIndex:index];
                NSNumber *distance = [NSNumber numberWithFloat:[beacon operateKalmanFilterWithObservation:RSSI.floatValue]];
                
                if ([uuidString isEqualToString:UUID5]) {
                    [self displayDistance:distance onIndex:1];
                }
                
                if ([uuidString isEqualToString:UUID6]) {
                    [self displayDistance:distance onIndex:2];
                }
                
                if ([uuidString isEqualToString:UUID7]) {
                    [self displayDistance:distance onIndex:3];
                }
            }
        }
    }
}

- (void)startScanning {
    [self stopScanning];
    [self positioning];
    [self.bluetoothManager scanForPeripheralsWithServices:nil options:nil];
}

- (void)stopScanning {
    if ([self.bluetoothManager isScanning]) {
        [self.bluetoothManager stopScan];
    }
}

#pragma mark - Supplementary Methods

- (void)displayDistance:(NSNumber *)distance onIndex:(NSInteger)index {
    NSString *display = [[NSString stringWithFormat:@"%.2f",distance.floatValue] stringByAppendingString:@" m"];
    
    switch (index) {
        case 1:
            self.beaconOne.text = display;
            break;
        case 2:
            self.beaconTwo.text = display;
            break;
        case 3:
            self.beaconThree.text = display;
        default:
            break;
    }
}

- (void)positioning {
    if ([self.beaconsUUID count] >= 3) {
        NSArray *position = [Trilateration trilaterateWithBeacons:self.beaconsList];
        float xval = [[position objectAtIndex:0] floatValue];
        float yval = [[position objectAtIndex:1] floatValue];
        
        if (circle1) {
            [circle1 removeFromSuperlayer];
            [circle2 removeFromSuperlayer];
            [circle3 removeFromSuperlayer];
        } else {
            circle1 =  [self createCircle];
            circle2 =  [self createCircle];
            circle3 =  [self createCircle];
        }
        
        BluetoothDevice *beacon1 = [self.beaconsList objectAtIndex:0];
        BluetoothDevice *beacon2 = [self.beaconsList objectAtIndex:1];
        BluetoothDevice *beacon3 = [self.beaconsList objectAtIndex:2];
        
        [self drawCircleX:beacon1.x.floatValue * MAP_SCALE Y:beacon1.y.floatValue * MAP_SCALE R:beacon1.distance.floatValue * MAP_SCALE Layer:circle1];
        [self drawCircleX:beacon2.x.floatValue * MAP_SCALE Y:beacon2.y.floatValue * MAP_SCALE R:beacon2.distance.floatValue * MAP_SCALE Layer:circle2];
        [self drawCircleX:beacon3.x.floatValue  *MAP_SCALE Y:beacon3.y.floatValue * MAP_SCALE R:beacon3.distance.floatValue * MAP_SCALE Layer:circle3];
        
        self.dot.center = CGPointMake(xval * MAP_SCALE, yval * MAP_SCALE);
        
        if (lastX != -1 && self.enableTracking) {
            UIBezierPath *path = [UIBezierPath bezierPath];
            [path moveToPoint:CGPointMake(lastX * MAP_SCALE, lastY * MAP_SCALE)];
            [path addLineToPoint:CGPointMake(xval * MAP_SCALE, yval * MAP_SCALE)];
            CAShapeLayer *shapeLayer = [CAShapeLayer layer];
            shapeLayer.path = [path CGPath];
            shapeLayer.strokeColor = [[UIColor blueColor] CGColor];
            shapeLayer.lineWidth = 3.0;
            [self.map.layer addSublayer:shapeLayer];
        }
        
        lastX = xval;
        lastY = yval;
        
        NSArray *abandonPosition = [Trilateration trilaterateAbandonWithBeacons:self.beaconsList];
        float abandon_xval = [[abandonPosition objectAtIndex:0] floatValue];
        float abandon_yval = [[abandonPosition objectAtIndex:1] floatValue];
        
        if (lastAbandonX != -1 && self.enableTracking) {
            UIBezierPath *path = [UIBezierPath bezierPath];
            [path moveToPoint:CGPointMake(lastAbandonX * MAP_SCALE, lastAbandonY * MAP_SCALE)];
            [path addLineToPoint:CGPointMake(abandon_xval * MAP_SCALE, abandon_yval * MAP_SCALE)];
            CAShapeLayer *shapeLayer = [CAShapeLayer layer];
            shapeLayer.path = [path CGPath];
            shapeLayer.strokeColor = [[UIColor redColor] CGColor];
            shapeLayer.lineWidth = 3.0;
            [self.map.layer addSublayer:shapeLayer];
        }
        
        lastAbandonX = abandon_xval;
        lastAbandonY = abandon_yval;
    }
}

- (CAShapeLayer *)createCircle {
    CAShapeLayer *solidLine =  [CAShapeLayer layer];
    solidLine.lineWidth = 2.0f ;
    solidLine.strokeColor = [UIColor orangeColor].CGColor;
    solidLine.fillColor = [UIColor clearColor].CGColor;
    
    return solidLine;
}

- (void)drawCircleX:(float)x Y:(float)y R:(float)r Layer:(CAShapeLayer *)layer{
    UIBezierPath *beizPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(x-r, y-r, 2*r, 2*r) cornerRadius:r];
    layer.path = beizPath.CGPath;
    layer.fillColor = [UIColor clearColor].CGColor;
    layer.strokeColor = [UIColor orangeColor].CGColor;
    layer.lineWidth = 2.0f;
    layer.lineCap=kCALineCapRound;
    [self.map.layer addSublayer:layer];
}

- (NSArray *)mean2D:(NSMutableArray *)data {
    float sumX = 0;
    float sumY = 0;
    
    for (int i = 0; i < [data count]; i++) {
        NSArray *element = [data objectAtIndex:i];
        sumX += [(NSNumber *)element[0] floatValue];
        sumY += [(NSNumber *)element[1] floatValue];
    }
    
    return [[NSArray alloc] initWithObjects:@(sumX / [data count]), @(sumY / [data count]), nil];
}

- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
