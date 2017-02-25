//
//  CoverViewController.h
//  Insider
//
//  Created by Lun on 2017/2/11.
//  Copyright © 2017年 Lun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PositionViewController.h"
#import "ModelViewController.h"

@interface CoverViewController : UIViewController

@property (weak, nonatomic) IBOutlet UISegmentedControl *dimensionSwitch;

@property (weak, nonatomic) IBOutlet UITextField *KF_Q;
@property (weak, nonatomic) IBOutlet UITextField *KF_R;

@property (weak, nonatomic) IBOutlet UITextField *PF_Q;
@property (weak, nonatomic) IBOutlet UITextField *PF_R;

- (IBAction)presentModel:(id)sender;
- (IBAction)presentPosition:(id)sender;

@end
