//
//  CoverViewController.m
//  Insider
//
//  Created by Lun on 2017/2/11.
//  Copyright © 2017年 Lun. All rights reserved.
//

#import "CoverViewController.h"

@interface CoverViewController ()

@end

@implementation CoverViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.KF_Q.text = @"0.000001";
    self.KF_R.text = @"0.0005";
    
    self.PF_Q.text = @"0.1";
    self.PF_R.text = @"0.05";
    
    [self.dimensionSwitch setSelectedSegmentIndex:1];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)presentModel:(id)sender {
    ModelViewController *mvc = [self.storyboard instantiateViewControllerWithIdentifier:@"model"];
    
    mvc.kalman_Q = [self.KF_Q.text floatValue];
    mvc.kalman_R = [self.KF_R.text floatValue];
    
    [self presentViewController:mvc animated:YES completion:nil];
}

- (IBAction)presentPosition:(id)sender {
    PositionViewController *pvc = [self.storyboard instantiateViewControllerWithIdentifier:@"position"];
    
    pvc.isTwoD = (self.dimensionSwitch.selectedSegmentIndex == 1);
    pvc.kalman_Q = [self.KF_Q.text floatValue];
    pvc.kalman_R = [self.KF_R.text floatValue];
    pvc.particle_Q = [self.PF_Q.text floatValue];
    pvc.particle_R = [self.PF_R.text floatValue];
    pvc.enableTracking = [self.trackingSwitch isOn]? YES: NO;
    
    [self presentViewController:pvc animated:YES completion:nil];
}

@end
