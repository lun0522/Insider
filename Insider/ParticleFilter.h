//
//  ParticleFilter.h
//  Insider
//
//  Created by Lun on 2017/2/21.
//  Copyright © 2017年 Lun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ParticleFilter : NSObject

@property (assign, nonatomic) UInt64 timestamp;
@property (assign, nonatomic) int dimension;
@property (assign, nonatomic) float worldWidth;
@property (assign, nonatomic) float worldHeight;
@property (assign, nonatomic) int population;
@property (strong, nonatomic) NSMutableArray *states;
@property (strong, nonatomic) NSMutableArray *weights;
@property (assign, nonatomic) float center;
@property (assign, nonatomic) float Q;
@property (assign, nonatomic) float R;
@property (assign, nonatomic) float den;

- (ParticleFilter *)initWithDimension:(int)dimension worldWidth:(float)width worldHeight:(float)height population:(int)population initValue:(float)value Q:(float)q R:(float)r;
- (float)filterWithObservation:(float)observation;
- (float)filterWithObservationX:(float)x Y:(float)y;

@end
