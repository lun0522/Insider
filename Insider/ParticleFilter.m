//
//  ParticleFilter.m
//  Insider
//
//  Created by Lun on 2017/2/21.
//  Copyright © 2017年 Lun. All rights reserved.
//

#import "ParticleFilter.h"

@implementation ParticleFilter

- (ParticleFilter *)initWithDimension:(int)dimension
                           worldWidth:(float)width
                          worldHeight:(float)height
                           population:(int)population
                                    Q:(float)q
                                    R:(float)r {
    if (self = [super init]) {
        _timestamp = [[NSDate date] timeIntervalSince1970] * 1000;
        _dimension = dimension;
        _worldWidth = width;
        _worldHeight = height;
        _population = population;
        _states = [[NSMutableArray alloc] initWithCapacity:population];
        _weights = [[NSMutableArray alloc] initWithCapacity:population];
        _center = -1;
        _Q = q;
        _R = r;
        _den = (float)sqrt(2 * M_PI * _R);
        
        NSAssert(_dimension == 1 || _dimension == 2, @"Dimension is invalid!");
        switch (_dimension) {
            case 1:
                for (int i = 0; i < _population; i++) {
                    [_states addObject:@((float)arc4random() / UINT32_MAX * _worldHeight)];
                    [_weights addObject:@(0.0)];
                }
                break;
            case 2:
                for (int i = 0; i < _population; i++) {
                    [_states addObject:[[NSArray alloc] initWithObjects:
                                        @((float)arc4random() / UINT32_MAX * _worldWidth),
                                        @((float)arc4random() / UINT32_MAX * _worldHeight),
                                        nil]];
                    [_weights addObject:@(0.0)];
                }
                break;
            default:
                break;
        }
    }
    
    return self;
}

- (float)filterWithObservation:(float)observation {
    NSAssert(_dimension == 1, @"Error in dimension!");
    
    _timestamp = [[NSDate date] timeIntervalSince1970] * 1000;
    
    for (int i = 0; i < _population; i++) {
        // Uniform distribution generator. See http://stackoverflow.com/a/12948538
        float u1 = (float)arc4random() / UINT32_MAX;      // uniform distribution
        float u2 = (float)arc4random() / UINT32_MAX;      // uniform distribution
        float f1 = sqrt(-2 * log(u1));
        float f2 = 2 * M_PI * u2;
        float gd = f1 * cos(f2);       // gaussian distribution
        
        float newState = [(NSNumber *)[_states objectAtIndex:i] floatValue] + _Q * gd;
        [_states replaceObjectAtIndex:i withObject:@(newState)];
        [_weights replaceObjectAtIndex:i withObject:@(exp(- pow(newState - observation, 2) / (2 * _R)) / _den)];
    }
    
    float sum_weights = [self sum:_weights];
    for (int i = 0; i < _population; i++) {
        [_weights replaceObjectAtIndex:i withObject:@([(NSNumber *)[_weights objectAtIndex:i] floatValue] / sum_weights)];
    }
    
    float max_weights = [self max:_weights];
    for (int i = 0; i < _population; i++) {
        float threshold = 2.0 * max_weights * arc4random() / UINT32_MAX;
        NSUInteger index = arc4random_uniform(_population);
        
        while ([(NSNumber *)[_weights objectAtIndex:index] floatValue] < threshold) {
            threshold -= [(NSNumber *)[_weights objectAtIndex:index++] floatValue];
            
            if (index >= _population) {
                index = 1;
            }
        }
        
        [_states replaceObjectAtIndex:i withObject:[_states objectAtIndex:index]];
    }
    
    _center = [self mean:_states];
    
    return _center;
}

- (float)filterWithObservationX:(float)x Y:(float)y {
    NSAssert(_dimension == 2, @"Error in dimension!");
    
    _timestamp = [[NSDate date] timeIntervalSince1970] * 1000;
    
    return _center;
}

- (float)sum:(NSMutableArray *)array {
    float summation = 0;
    
    for (int i = 0; i < [array count]; i++) {
        summation += [(NSNumber *)[array objectAtIndex:i] floatValue];
    }
    
    return summation;
}

- (float)mean:(NSMutableArray *)array {
    return (float)[self sum:array] / [array count];
}

- (float)max:(NSMutableArray *)array {
    float maximum = [(NSNumber *)[array objectAtIndex:0] floatValue];
    
    for (int i = 1; i < [array count]; i++) {
        float number = [(NSNumber *)[array objectAtIndex:i] floatValue];
        
        if (number > maximum) {
            maximum = number;
        }
    }
    
    return maximum;
}

@end
