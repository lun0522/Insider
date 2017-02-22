//
//  Trilateration.m
//  Insider
//
//  Created by Lun on 2017/2/12.
//  Copyright © 2017年 Lun. All rights reserved.
//

#import "Trilateration.h"

@implementation Trilateration

+ (NSArray *)trilaterateWithBeacons:(NSMutableArray *)beacons {
    if ([beacons count] >= 3) {
        NSMutableArray *useBeacons = [beacons mutableCopy];
        
        // TODO: more than 3
        if ([beacons count] > 3) {
            NSLog(@"More than 3!");
            return nil;
        }
        
        // P1,P2,P3 is the point and 2-dimension vector
        BluetoothDevice *beacon1 = [useBeacons objectAtIndex:0];
        BluetoothDevice *beacon2 = [useBeacons objectAtIndex:1];
        BluetoothDevice *beacon3 = [useBeacons objectAtIndex:2];
        
        // this is the distance between all the points and the unknown point
        CGFloat P1[] = { beacon1.x.doubleValue, beacon1.y.doubleValue, 0 };
        CGFloat P2[] = { beacon2.x.doubleValue, beacon2.y.doubleValue, 0 };
        CGFloat P3[] = { beacon3.x.doubleValue, beacon3.y.doubleValue, 0 };
        
        CGFloat distA = beacon1.distance.doubleValue;
        CGFloat distB = beacon2.distance.doubleValue;
        CGFloat distC = beacon3.distance.doubleValue;
        
        // ex = (P2 - P1)/(numpy.linalg.norm(P2 - P1))
        CGFloat ex[] = { 0, 0, 0 };
        CGFloat P2P1 = 0;
        
        for (NSUInteger i = 0; i < 3; i++) {
            P2P1 += pow(P2[i] - P1[i], 2);
        }
        
        for (NSUInteger i = 0; i < 3; i++) {
            ex[i] = (P2[i] - P1[i]) / sqrt(P2P1);
        }
        
        // i = dot(ex, P3 - P1)
        CGFloat p3p1[] = { 0, 0, 0 };
        
        for (NSUInteger i = 0; i < 3; i++) {
            p3p1[i] = P3[i] - P1[i];
        }
        
        CGFloat ivar = 0;
        
        for (NSUInteger i = 0; i < 3; i++) {
            ivar += (ex[i] * p3p1[i]);
        }
        
        // ey = (P3 - P1 - i*ex)/(numpy.linalg.norm(P3 - P1 - i*ex))
        CGFloat p3p1i = 0;
        
        for (NSUInteger  i = 0; i < 3; i++) {
            p3p1i += pow(P3[i] - P1[i] - ex[i] * ivar, 2);
        }
        
        CGFloat ey[] = { 0, 0, 0};
        
        for (NSUInteger i = 0; i < 3; i++) {
            ey[i] = (P3[i] - P1[i] - ex[i] * ivar) / sqrt(p3p1i);
        }
        
        // ez = numpy.cross(ex,ey)
        // if 2-dimensional vector then ez = 0
        CGFloat ez[] = { 0, 0, 0 };
        
        // d = numpy.linalg.norm(P2 - P1)
        CGFloat d = sqrt(P2P1);
        
        // j = dot(ey, P3 - P1)
        CGFloat jvar = 0;
        
        for (NSUInteger i = 0; i < 3; i++) {
            jvar += (ey[i] * p3p1[i]);
        }
        
        // from wikipedia
        // plug and chug using above values
        CGFloat x = (pow(distA, 2) - pow(distB, 2) + pow(d, 2)) / (2 * d);
        CGFloat y = ((pow(distA, 2) - pow(distC, 2) + pow(ivar, 2)
                      + pow(jvar, 2)) / (2 * jvar)) - ((ivar / jvar) * x);
        
        // only one case shown here
        CGFloat z = sqrt(pow(distA, 2) - pow(x, 2) - pow(y, 2));
        
        if (isnan(z)) z = 0;
        
        // triPt is an array with ECEF x,y,z of trilateration point
        // triPt = P1 + x*ex + y*ey + z*ez
        CGFloat triPt[] = { 0, 0, 0 };
        
        for (NSUInteger i = 0; i < 3; i++) {
            triPt[i] =  P1[i] + ex[i] * x + ey[i] * y + ez[i] * z;
        }
        
        return [[NSArray alloc] initWithObjects:@(triPt[0]), @(triPt[1]), nil];
    } else {
        NSLog(@"Beacons not enough!");
        return nil;
    }
}

@end
