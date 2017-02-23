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
        _centerX = -1;
        _centerY = -1;
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
        float newState = [(NSNumber *)[_states objectAtIndex:i] floatValue] + _Q * [self generateGaussian];
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
    
    _centerY = [self mean1D:_states];
    
    return _centerY;
}

- (NSArray *)filterWithObservationX:(float)x Y:(float)y {
    NSAssert(_dimension == 2, @"Error in dimension!");
    
    _timestamp = [[NSDate date] timeIntervalSince1970] * 1000;
    
    for (int i = 0; i < _population; i++) {
        NSArray *oldState = [_states objectAtIndex:i];
        float oldX = [(NSNumber *)oldState[0] floatValue];
        float oldY = [(NSNumber *)oldState[1] floatValue];
        float newX = oldX + [self generateGaussian];
        float newY = oldY + [self generateGaussian];
        
        [_states replaceObjectAtIndex:i withObject:[[NSArray alloc] initWithObjects:@(newX), @(newY), nil]];
        [_weights replaceObjectAtIndex:i withObject:@(exp(- (pow(newX - x, 2) + pow(newY - y, 2)) / (2 * _R)) / _den)];
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
    
    NSArray *center = [self mean2D:_states];
    _centerX = [(NSNumber *)center[0] floatValue];
    _centerY = [(NSNumber *)center[1] floatValue];
    
    return center;
}

- (float)sum:(NSMutableArray *)data {
    float summation = 0;
    
    for (int i = 0; i < [data count]; i++) {
        summation += [(NSNumber *)[data objectAtIndex:i] floatValue];
    }
    
    return summation;
}

- (float)mean1D:(NSMutableArray *)data {
    return (float)[self sum:data] / [data count];
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

- (float)max:(NSMutableArray *)data {
    float maximum = [(NSNumber *)[data objectAtIndex:0] floatValue];
    
    for (int i = 1; i < [data count]; i++) {
        float number = [(NSNumber *)[data objectAtIndex:i] floatValue];
        
        if (number > maximum) {
            maximum = number;
        }
    }
    
    return maximum;
}

- (float)generateGaussian {
    // Gaussian distribution generator. See http://stackoverflow.com/a/12948538
    float u1 = (float)arc4random() / UINT32_MAX;
    float u2 = (float)arc4random() / UINT32_MAX;
    float f1 = sqrt(-2 * log(u1));
    float f2 = 2 * M_PI * u2;
    
    return f1 * cos(f2);
}

@end
