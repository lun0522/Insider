//
//  KalmanFilter.m
//  Insider
//
//  Created by Lun on 2017/2/11.
//  Copyright © 2017年 Lun. All rights reserved.
//

#import "KalmanFilter.h"

@implementation KalmanFilter

- (KalmanFilter *)initWithQ:(float)q R:(float)r X0:(float)x0 P0:(float)p0 {
    if (self = [super init]) {
        _timestamp = [[NSDate date] timeIntervalSince1970] * 1000;
        _Q = q;
        _R = r;
        _K = 0;
        _X = x0;
        _P = p0;
    }
    
    return self;
}

- (float)filterWithObservation:(float)observation {
    /*-----------------------------------------------*\
    |  Simplified Kalman Filter equations             |
    |                                                 |
    |  state equation                                 |
    |  x(k) = x(k-1) + w(k)                           |
    |                                                 |
    |  observations equation                          |
    |  z(k) = x(k) + y(k)                             |
    |                                                 |
    |  prediction equations                           |
    |  x(k|k-1) = x(k-1|k-1)                          |
    |  P(k|k-1) = P(k-1|k-1) + Q                      |
    |                                                 |
    |  correction equations                           |
    |  K(k) = P(k|k-1)·(P(k|k-1) + R)^(-1)            |
    |  x(k|k) = x(k|k-1) + K(k)·(z(k) - x(k|k-1))     |
    |  P(k|k) = (I - K(k))·P(k|k-1)                   |
    |                                                 |
    |  Iteration equations                            |
    |  K(k) = P(k|k-1)/(P(k|k-1) + R)                 |
    |  x(k|k) = x(k-1|k-1) + K(k)·(z(k) - x(k-1|k-1)) |
    |  P(k+1|k) = (1 - K(k))·P(k|k-1) + Q             |
    \*-----------------------------------------------*/
    
    _timestamp = [[NSDate date] timeIntervalSince1970] * 1000;
    _K = _P / (_P + _R);
    _X = _X + _K * (observation - _X);
    _P = (1 - _K) * _P + _Q;
    
    return _X;
}

@end
