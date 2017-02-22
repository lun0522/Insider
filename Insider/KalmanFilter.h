//
//  KalmanFilter.h
//  Insider
//
//  Created by Lun on 2017/2/11.
//  Copyright © 2017年 Lun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KalmanFilter : NSObject

/*-----------------------------------------------*\
|  Kalman Filter equations                        |
|                                                 |
|  state equation                                 |
|  x(k) = A·x(k-1) + B·u(k) + w(k-1)              |
|                                                 |
|  observations equation                          |
|  z(k) = H·x(k) + y(k)                           |
|                                                 |
|  prediction equations                           |
|  x(k|k-1) = A·x(k-1|k-1) + B·u(k)               |
|  P(k|k-1) = A·P(k-1|k-1)·A^T + Q                |
|                                                 |
|  correction equations                           |
|  K(k) = P(k|k-1)·H^T·(H·P(k|k-1)·H^T + R)^(-1)  |
|  x(k|k) = x(k|k-1) + K(k)·(z(k) - H·x(k|k-1))   |
|  P(k|k) = (I - K(k)·H)·P(k|k-1)                 |
\*-----------------------------------------------*/

@property (assign, nonatomic) UInt64 timestamp;
@property (assign, nonatomic) float Q;              // Process noise covariance
@property (assign, nonatomic) float R;              // Observation noise covariance
@property (assign, nonatomic) float K;              // Kalman gain
@property (assign, nonatomic) float X;              // Estimated state
@property (assign, nonatomic) float P;              // Estimated covariance

- (KalmanFilter *)initWithQ:(float)q R:(float)r X0:(float)x0 P0:(float)p0;
- (float)filterWithObservation:(float)observation;

@end
