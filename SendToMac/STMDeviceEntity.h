//
//  STMDeviceEntity.h
//  SendToMac
//
//  Created by Maarten Billemont on 12/03/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface STMDeviceEntity : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic) int64_t identifier;
@property (nonatomic) BOOL trusted;
@property (nonatomic) BOOL blocked;

@end
