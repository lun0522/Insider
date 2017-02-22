//
//  ModelViewController.m
//  Insider
//
//  Created by Lun on 2017/1/19.
//  Copyright © 2017年 Lun. All rights reserved.
//

#import "ModelViewController.h"

@interface ModelViewController ()

@end

@implementation ModelViewController

#pragma mark - Lifecycle Methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initBoolean];
    [self initText];
    [self initButton];
    [self initTableView];
    [self initArray];
    [self initChart];
    [self initBluetooth];
    [self initTimer];
    [self initBlurEffect];
    [self initIndicator];
    [self initProgress];
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

- (void)initBoolean {
    self.isDistance = YES;
    self.isSampling = NO;
    self.isCharting = NO;
}

- (void)initText {
    self.sampleSize.text = [NSString stringWithFormat:@"%d",DEFAULT_SAMPLE_SIZE];
    
    self.sampleSize.keyboardType = UIKeyboardTypeDecimalPad;
    self.distORang.keyboardType = UIKeyboardTypeDecimalPad;
    
    self.samplingText = [[UITextField alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 20.0)];
    self.samplingText.center = CGPointMake(self.view.center.x, self.view.center.y * 0.8);
    self.samplingText.text = @"  Sampling...";
    self.samplingText.font = [UIFont systemFontOfSize:20.0];
    self.samplingText.textColor = [UIColor whiteColor];
    self.samplingText.textAlignment = NSTextAlignmentCenter;
    
    self.sizeIndicator.userInteractionEnabled = YES;
    [self.sizeIndicator addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapSize:)]];
    
    self.DAIndicator.userInteractionEnabled = YES;
    [self.DAIndicator addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDistAng:)]];
}

- (void)initButton {
    [self.recordButton addTarget:self
                          action:@selector(record)
                forControlEvents:UIControlEventTouchUpInside];
    [self disableRecordButton];
    
    [self.backButton addTarget:self
                          action:@selector(dismiss)
                forControlEvents:UIControlEventTouchUpInside];
}

- (void)initTableView {
    self.deviceList.delegate = self;
    self.deviceList.dataSource = self;
    
    self.rssiList.delegate = self;
    self.rssiList.dataSource = self;
}

- (void)initArray {
    self.devicesUUID = [[NSMutableArray alloc] init];
    self.devicesInfo = [[NSMutableArray alloc] init];
    self.sampledUUID = [[NSMutableArray alloc] init];
    
    self.rawData = [[NSMutableArray alloc] initWithCapacity:CHART_CAPACITY];
    self.KalmanData = [[NSMutableArray alloc] initWithCapacity:CHART_CAPACITY];
    self.ParticleData = [[NSMutableArray alloc] initWithCapacity:CHART_CAPACITY];
    
    for (int i = 0; i < CHART_CAPACITY; i++) {
        [self.rawData addObject:@(CHART_INIT_VALUE)];
        [self.KalmanData addObject:@(CHART_INIT_VALUE)];
        [self.ParticleData addObject:@(CHART_INIT_VALUE)];
    }
}

- (void)initChart {
    PNLineChartData *data1 = [self chartWithR:52.0 g:152.0 b:219.0 array:self.rawData];
    PNLineChartData *data2 = [self chartWithR:231.0 g:76.0 b:60.0 array:self.KalmanData];
    PNLineChartData *data3 = [self chartWithR:241.0 g:196.0 b:15.0 array:self.ParticleData];
    
    self.lineChart = [[PNLineChart alloc] initWithFrame:CGRectMake(0, 0, self.chartView.frame.size.width, self.chartView.frame.size.height)];
    self.lineChart.showYGridLines = YES;
    NSMutableArray *xLabel = [[NSMutableArray alloc] initWithCapacity:CHART_CAPACITY];
    for (int i = 0; i < CHART_CAPACITY; i++) {
        [xLabel addObject:@""];
    }
    [self.lineChart setXLabels:xLabel];
    [self.lineChart setYLabels:@[@"-90", @"-80", @"-70", @"-60", @"-50", @"-40", @"-30"]];
    self.lineChart.yFixedValueMax = RSSI_MAXIMUM;
    self.lineChart.yFixedValueMin = RSSI_MINIMUM;
    self.lineChart.displayAnimated = NO;
    self.lineChart.chartData = @[data1, data2, data3];
    
    [self.lineChart strokeChart];
    [self.chartView addSubview:self.lineChart];
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

- (void)initBlurEffect {
    self.blurEffect = [[UIVisualEffectView alloc] init];
    self.blurEffect.frame = self.view.frame;
    self.blurEffect.alpha = 0.9;
}

- (void)initIndicator {
    self.samplingIndicator = [[UIActivityIndicatorView  alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.samplingIndicator.center = CGPointMake(self.view.center.x, self.view.center.y);
    self.samplingIndicator.hidesWhenStopped = YES;
}

- (void)initProgress {
    self.samplingProgress = [[UIProgressView alloc]initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.samplingProgress.frame = CGRectMake(self.view.center.x / 2, self.view.center.y * 1.17, self.view.center.x, 10.0);
}

#pragma mark - Bluetooth

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    NSString *state = @"Current State of Bluetooth - ";
    
    if (central.state == CBManagerStatePoweredOn) {
        state = [state stringByAppendingString:@"Powered on"];
        
        [self.timer setFireDate:[NSDate distantPast]];
        [self enableRecordButton];
    } else {
        switch (central.state) {
            case CBManagerStateUnknown:
                state = [state stringByAppendingString:@"Unknown"];
                break;
            case CBManagerStateResetting:
                state = [state stringByAppendingString:@"Resetting"];
                break;
            case CBManagerStateUnsupported:
                state = [state stringByAppendingString:@"Unsupported"];
                break;
            case CBManagerStateUnauthorized:
                state = [state stringByAppendingString:@"Unauthorized"];
                break;
            case CBManagerStatePoweredOff:
                state = [state stringByAppendingString:@"Powered off"];
                break;
            default:
                break;
        }
        [self stopScanning];
        [self.timer setFireDate:[NSDate distantFuture]];
        [self disableRecordButton];
        
        if (self.isSampling) {
            self.isSampling = NO;
            [self.samplingProgress removeFromSuperview];
            [self stopSamplingAnimation:bluetoothShutDown];
        }
    }
    
    self.bluetoothState.text = state;
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary<NSString *,id> *)advertisementData
                  RSSI:(NSNumber *)RSSI {
    if (RSSI.intValue <= RSSI_MAXIMUM && RSSI.intValue >= RSSI_MINIMUM) {
        NSString *uuidString = peripheral.identifier.UUIDString;
        
        if (![self.devicesUUID containsObject:uuidString]) {
            BluetoothDevice *device = [[BluetoothDevice alloc] initWithUUID:uuidString
                                                                       RSSI:RSSI];
            
            [self.sampledUUID addObject:uuidString];
            [self.devicesUUID addObject:uuidString];
            [self.devicesInfo addObject:device];
            [self.deviceList reloadData];
            [self.rssiList reloadData];
        } else if (![self.sampledUUID containsObject:uuidString]) {
            [self.sampledUUID addObject:uuidString];
            
            NSInteger index = [self.devicesUUID indexOfObject:uuidString];
            BluetoothDevice *device = [[self devicesInfo] objectAtIndex:index];
            device.deviceRSSI = RSSI;
            
            [self.rssiList reloadData];
            
            if (self.isSampling && [uuidString isEqualToString:self.beingSampledBeacon.deviceUUID]) {
                [self.beingSampledBeacon.historyData addObject:[NSNumber numberWithInt:RSSI.intValue]];
                
                if (self.sampleSize.text.intValue != 0) {
                    [self.samplingProgress setProgress:(float)[self.beingSampledBeacon.historyData count] / (float)self.sampleSize.text.intValue animated:YES];
                    
                    if ([self.beingSampledBeacon.historyData count] == self.sampleSize.text.intValue) {
                        self.isSampling = NO;
                        
                        [self upload];
                    }
                }
            }
            
            if (self.isCharting && [uuidString isEqualToString:self.beingSampledBeacon.deviceUUID]) {
                [self.rawData removeObjectAtIndex:0];
                [self.KalmanData removeObjectAtIndex:0];
                [self.ParticleData removeObjectAtIndex:0];

                if (!self.beingSampledBeacon.kalmanFilter) {
                    self.beingSampledBeacon.kalmanFilter = [[KalmanFilter alloc]
                                                            initWithQ:self.kalman_Q
                                                                    R:self.kalman_R
                                                                   X0:RSSI.floatValue
                                                                   P0:DEFAULT_P0];
                    
                    self.beingSampledBeacon.particleFilter = [[ParticleFilter alloc]
                                                              initWithDimension:1
                                                                     worldWidth:0
                                                                    worldHeight:-100
                                                                     population:DEFAULT_POPULATION
                                                                      initValue:RSSI.floatValue
                                                                              Q:self.particle_Q
                                                                              R:self.particle_R];
                } else {
                    [self.beingSampledBeacon operateKalmanFilterWithObservation:RSSI.floatValue];
                    [self.beingSampledBeacon operateParticleFilterWithObservation:RSSI.floatValue];
                }
                
                [self.rawData addObject:RSSI];
                [self.KalmanData addObject:@(self.beingSampledBeacon.kalmanFilter.X)];
                [self.ParticleData addObject:@(self.beingSampledBeacon.particleFilter.center)];
                
                PNLineChartData *data1 = [self chartWithR:52.0 g:152.0 b:219.0 array:self.rawData];
                PNLineChartData *data2 = [self chartWithR:231.0 g:76.0 b:60.0 array:self.KalmanData];
                PNLineChartData *data3 = [self chartWithR:241.0 g:196.0 b:15.0 array:self.ParticleData];
                
                [self.lineChart updateChartData:@[data1, data2, data3] withAnimation:NO];
            }
        }
    }
}

- (void)startScanning {
    [self stopScanning];
    [self.sampledUUID removeAllObjects];
    [self.bluetoothManager scanForPeripheralsWithServices:nil options:nil];
}

- (void)stopScanning {
    if ([self.bluetoothManager isScanning]) {
        [self.bluetoothManager stopScan];
    }
}

#pragma mark - TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.devicesInfo count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = [indexPath row];
    
    UITableViewCell *cell;
    
    if ([tableView isEqual:self.deviceList]) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:nil];
        
        if (row < [self.devicesInfo count]) {
            BluetoothDevice *device = [self.devicesInfo objectAtIndex:row];
            
            if ([device.deviceUUID isEqualToString:UUID1]) {
                cell.textLabel.text = textBeacon1;
            } else if ([device.deviceUUID isEqualToString:UUID2]) {
                cell.textLabel.text = textBeacon2;
            } else if ([device.deviceUUID isEqualToString:UUID3]) {
                cell.textLabel.text = textBeacon3;
            } else {
                cell.textLabel.text = device.deviceUUID;
            }
            
            cell.textLabel.font = [UIFont systemFontOfSize:20.0];
        }
        
        cell.userInteractionEnabled = row < [self.devicesInfo count] ? YES : NO;
    } else {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:nil];
        
        if (row < [self.devicesInfo count]) {
            BluetoothDevice *device = [self.devicesInfo objectAtIndex:row];
            cell.textLabel.text = [NSString stringWithFormat:@"%d",[device.deviceRSSI intValue]];
        }
        
        cell.userInteractionEnabled = NO;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = [indexPath row];
    
    BluetoothDevice *device = [self.devicesInfo objectAtIndex:row];
    self.beingSampledBeacon = device;
    NSString *selected = [[[tableView cellForRowAtIndexPath:indexPath] textLabel] text];
    
    if (![selected isEqualToString:self.beaconName.text]) {
        if ([selected isEqualToString:textBeacon1] || [selected isEqualToString:textBeacon2] || [selected isEqualToString:textBeacon3]) {
            self.isCharting = YES;
            
            [self.rawData removeAllObjects];
            [self.KalmanData removeAllObjects];
            [self.ParticleData removeAllObjects];
            
            for (int i = 0; i < CHART_CAPACITY; i++) {
                [self.rawData addObject:@(CHART_INIT_VALUE)];
                [self.KalmanData addObject:@(CHART_INIT_VALUE)];
                [self.ParticleData addObject:@(CHART_INIT_VALUE)];
            }
        } else {
            self.isCharting = NO;
        }
        
        self.beaconName.text = selected;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == self.deviceList) {
        [self tableView:self.rssiList scrollFollow:self.deviceList];
    }else{
        [self tableView:self.deviceList scrollFollow:self.rssiList];
    }
}

- (void)tableView:(UITableView *)tableView1 scrollFollow:(UITableView *)tableView2 {
    CGPoint offset = tableView1.contentOffset;
    offset.y = tableView2.contentOffset.y;
    tableView1.contentOffset = offset;
}

#pragma mark - Supplementary Methods

- (void)record {
    if ([self isPureInt:self.sampleSize.text] && self.beaconName.text.length != 0 && [self isPureFloat:self.distORang.text]) {
        [self.beingSampledBeacon.historyData removeAllObjects];
        
        self.isSampling = YES;
        
        if (self.sampleSize.text.intValue != 0) {
            [self startSamplingAnimation];
        } else {
            UIAlertController *alert;
            alert = [UIAlertController alertControllerWithTitle:@"Sampling..."
                                                        message:@""
                                                 preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Finish"
                                                             style:UIAlertActionStyleDestructive
                                                           handler:^(UIAlertAction *action) {
                                                               self.isSampling = NO;
                                                               
                                                               AVObject *data = [[AVObject alloc] initWithClassName:@"TempData"];
                                                               [data setObject:self.beingSampledBeacon.deviceUUID forKey:@"deviceUUID"];
                                                               [data setObject:self.beingSampledBeacon.historyData forKey:@"data"];
                                                               [data saveInBackground];
                                                           }];
            [alert addAction:cancel];
            [self presentViewController:alert animated:YES completion:nil];
        }
    } else {
        UIAlertController *alert;
        alert = [UIAlertController alertControllerWithTitle:@""
                                                    message:@""
                                             preferredStyle:UIAlertControllerStyleAlert];
        
        if (![self isPureFloat:self.distORang.text]) {
            alert.title = self.isDistance? @"Distance is invalid!": @"Angle is invalid!";
        }
        
        if (self.beaconName.text.length == 0) {
            alert.title = @"Please choose a beacon!";
        }
        
        if (![self isPureInt:self.sampleSize.text]) {
            alert.title = @"Sample size is invalid!";
        }
        
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"OK"
                                                         style:UIAlertActionStyleCancel
                                                       handler:nil];
        [alert addAction:cancel];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)upload {
    self.samplingText.text = @"   Uploading...";
    [self.samplingProgress removeFromSuperview];
    
    NSNumberFormatter* numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    
    AVObject *data = [[AVObject alloc] initWithClassName:self.isDistance? @"DistanceData": @"AngleData"];
    [data setObject:self.beingSampledBeacon.deviceUUID forKey:@"deviceUUID"];
    [data setObject:self.beingSampledBeacon.historyData forKey:@"data"];
    [data setObject:[numberFormatter numberFromString:self.distORang.text]
             forKey:self.isDistance? @"distance": @"angle"];
    
    [data saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            self.samplingText.text = @"  Calculating...";
            
            NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
            [parameters setValue:data.objectId forKey:@"sourceId"];
            [parameters setValue:self.isDistance? @"distance": @"angle" forKey:@"dataType"];
            if (self.isDistance) {      // No UUID, no modeling
                [parameters setValue:self.beingSampledBeacon.deviceUUID forKey:@"targetUUID"];
            }
            
            [AVCloud callFunctionInBackground:@"GaussianFiltering"
                               withParameters:parameters
                                        block:^(id object, NSError *error) {
                                            if(error != nil){
                                                NSLog(@"Failed in filtering: %@",error);
                                                
                                                [self stopSamplingAnimation:filterFailed];
                                            } else {
                                                [self stopSamplingAnimation:accomplished];
                                            }
                                        }];
        } else {
            NSLog(@"Failed in uploading: %@",error);
            
            [self stopSamplingAnimation:uploadFailed];
        }
    }];
}

- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)startSamplingAnimation {
    self.view.userInteractionEnabled = NO;
    
    self.samplingText.text = @"  Sampling...";
    [self.samplingIndicator startAnimating];
    [self.samplingProgress setProgress:0.0];
    
    [self.view addSubview:self.blurEffect];
    
    [UIView animateWithDuration:0.3 animations:^{
        self.blurEffect.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    } completion:^(BOOL finished) {
        [self.view addSubview:self.samplingText];
        [self.view addSubview:self.samplingIndicator];
        [self.view addSubview:self.samplingProgress];
    }];
}

- (void)stopSamplingAnimation:(NSInteger)reason {
    self.view.userInteractionEnabled = YES;
    
    [self.samplingIndicator stopAnimating];
    
    [self.samplingText removeFromSuperview];
    [self.samplingIndicator removeFromSuperview];
    
    [UIView animateWithDuration:0.3 animations:^{
        self.blurEffect.effect = nil;
    } completion:^(BOOL finished) {
        [self.blurEffect removeFromSuperview];
        
        UIAlertController *alert;
        alert = [UIAlertController alertControllerWithTitle:@""
                                                    message:@""
                                             preferredStyle:UIAlertControllerStyleAlert];
        
        switch (reason) {
            case bluetoothShutDown:
                alert.title = @"Failed!";
                alert.message = @"Bluetooth is shut down";
                break;
            case uploadFailed:
                alert.title = @"Failed in uploading.";
                break;
            case filterFailed:
                alert.title = @"Failed in filtering.";
                break;
            case accomplished:
                alert.title = @"Successful!";
                break;
            default:
                break;
        }
        
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"OK"
                                                         style:UIAlertActionStyleCancel
                                                       handler:nil];
        [alert addAction:cancel];
        [self presentViewController:alert animated:YES completion:nil];
    }];
}

- (void)enableRecordButton {
    self.recordButton.userInteractionEnabled = YES;
    self.recordButton.alpha = 1.0;
    [self.recordButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
}

- (void)disableRecordButton {
    self.recordButton.userInteractionEnabled = NO;
    self.recordButton.alpha = 0.4;
    [self.recordButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
}

- (BOOL)isPureInt:(NSString *)string {
    NSScanner *scan = [NSScanner scannerWithString:string];
    int val;
    return [scan scanInt:&val] && [scan isAtEnd] && string.intValue >= 0;
}

- (BOOL)isPureFloat:(NSString *)string {
    NSScanner *scan = [NSScanner scannerWithString:string];
    float val;
    return [scan scanFloat:&val] && [scan isAtEnd] && string.floatValue >= 0;
}

- (void)tapSize:(UITapGestureRecognizer*)recognizer {
    self.sampleSize.text = [self.sampleSize.text isEqualToString:@"0"]? [NSString stringWithFormat:@"%d",DEFAULT_SAMPLE_SIZE]: @"0";
}

- (void)tapDistAng:(UITapGestureRecognizer*)recognizer {
    self.isDistance = !self.isDistance;
    self.DAIndicator.text = self.isDistance? @"Distance": @"Angle";
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [self.sampleSize resignFirstResponder];
    [self.distORang resignFirstResponder];
}

- (PNLineChartData *)chartWithR:(float)red
                              g:(float)green
                              b:(float)blue
                          array:(NSMutableArray *)array {
    PNLineChartData *data = [PNLineChartData new];
    
    data.color = [UIColor colorWithRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:1.0];
    data.itemCount = [array count];
    data.getData = ^(NSUInteger index) {
        CGFloat yValue = [array[index] floatValue];
        return [PNLineChartDataItem dataItemWithY:yValue];
    };
    
    return data;
}

@end